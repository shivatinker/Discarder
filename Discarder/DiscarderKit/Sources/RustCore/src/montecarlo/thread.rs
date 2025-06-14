use super::message::{Chunk, Message, MessageContent};
use super::traits::MonteCarloAlgorithm;
use std::sync::mpsc;

pub struct MonteCarloThread<Algorithm: MonteCarloAlgorithm> {
    thread_id: usize,
    sender: mpsc::Sender<Message<Algorithm::Output>>,
    algorithm: Algorithm,
    chunk_size: usize,
}

impl<Algorithm: MonteCarloAlgorithm> MonteCarloThread<Algorithm> {
    pub fn new(
        thread_id: usize,
        sender: mpsc::Sender<Message<Algorithm::Output>>,
        algorithm: Algorithm,
        chunk_size: usize,
    ) -> Self {
        Self {
            thread_id,
            sender,
            algorithm,
            chunk_size,
        }
    }

    pub fn run(mut self, iterations: usize) {
        let mut remaining = iterations;

        while remaining > 0 {
            let batch_size = remaining.min(self.chunk_size);
            let mut chunk = Chunk::<Algorithm::Output>::new();

            for _ in 0..batch_size {
                self.algorithm.sample(&mut chunk.output);
                chunk.iterations_done += 1;
            }

            let message = Message {
                thread_id: self.thread_id,
                content: MessageContent::Chunk(chunk),
            };

            self.sender.send(message).unwrap_or_else(|e| {
                eprintln!("Error sending chunk: {:?}", e);
            });

            remaining -= batch_size;
        }

        let message = Message {
            thread_id: self.thread_id,
            content: MessageContent::Done,
        };

        self.sender.send(message).unwrap_or_else(|e| {
            eprintln!("Error sending done message: {:?}", e);
        });
    }
}
