mod config;
mod message;
mod thread;
mod traits;

#[cfg(test)]
mod tests;

pub use config::*;
pub use message::*;
pub use traits::*;

use rand::{RngCore, SeedableRng};
use rand_pcg::Pcg64;
use std::{collections::HashSet, sync::mpsc, thread as std_thread};
use thread::MonteCarloThread;

pub struct MonteCarlo<Factory: MonteCarloAlgorithmFactory> {
    chunk:
        Chunk<<<Factory as MonteCarloAlgorithmFactory>::Algorithm as MonteCarloAlgorithm>::Output>,
    factory: Factory,
    configuration: MonteCarloConfiguration,
    rng: Pcg64,
}

pub struct Progress<'a, Algorithm: MonteCarloAlgorithm> {
    pub fraction_completed: f64,
    pub chunk: &'a Chunk<<Algorithm as MonteCarloAlgorithm>::Output>,
}

impl<Factory: MonteCarloAlgorithmFactory> MonteCarlo<Factory> {
    pub fn new(
        factory: Factory,
        configuration: MonteCarloConfiguration,
        seed: u64,
    ) -> Self {
        Self {
            chunk: Chunk::new(),
            factory,
            configuration,
            rng: Pcg64::seed_from_u64(seed),
        }
    }

    pub fn run(
        &mut self,
        iterations: usize,
        progress_handler: impl Fn(
            &Progress<'_, <Factory as MonteCarloAlgorithmFactory>::Algorithm>,
        ),
    ) -> Chunk<<<Factory as MonteCarloAlgorithmFactory>::Algorithm as MonteCarloAlgorithm>::Output>{
        let initial_iterations = self.chunk.iterations_done;

        println!(
            "Running Monte Carlo with {} threads",
            self.configuration.threads
        );
        println!("Iterations: {}", iterations);
        println!("Chunk size: {}", self.configuration.chunk_size);

        let (sender, receiver) = mpsc::channel::<
            Message<<Factory::Algorithm as MonteCarloAlgorithm>::Output>,
        >();
        let base_iterations = iterations / self.configuration.threads;
        let remainder = iterations % self.configuration.threads;

        for thread_id in 0..self.configuration.threads {
            let sender = sender.clone();
            let thread_seed = self.rng.next_u64();
            let algorithm = self.factory.make(thread_seed);
            let chunk_size = self.configuration.chunk_size;

            // First 'remainder' threads get one extra iteration
            let thread_iterations = if thread_id < remainder {
                base_iterations + 1
            } else {
                base_iterations
            };

            std_thread::Builder::new()
                .name(format!("montecarlo-{}", thread_id))
                .spawn(move || {
                    // println!(
                    //     "Thread {} started with seed {}",
                    //     thread_id, thread_seed
                    // );

                    let thread = MonteCarloThread::new(
                        thread_id, sender, algorithm, chunk_size,
                    );
                    thread.run(thread_iterations);
                })
                .unwrap();
        }

        drop(sender);

        let mut done_threads = HashSet::<usize>::new();

        loop {
            match receiver.recv() {
                Ok(message) => match message.content {
                    MessageContent::Chunk(chunk) => {
                        self.chunk.merge(&chunk);

                        let progress = Progress {
                            fraction_completed: (self.chunk.iterations_done
                                - initial_iterations)
                                as f64
                                / (iterations - initial_iterations) as f64,
                            chunk: &self.chunk,
                        };

                        progress_handler(&progress);
                    }
                    MessageContent::Done => {
                        // println!("Thread {} finished", message.thread_id);
                        done_threads.insert(message.thread_id);

                        if done_threads.len() == self.configuration.threads {
                            return self.chunk.clone();
                        }
                    }
                },
                Err(e) => {
                    eprintln!("Some shit happened: {:?}", e);
                    return self.chunk.clone();
                }
            }
        }
    }
}
