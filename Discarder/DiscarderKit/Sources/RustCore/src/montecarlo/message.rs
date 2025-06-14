use super::traits::MonteCarloOutput;

#[derive(Clone)]
pub struct Chunk<Output: MonteCarloOutput> {
    pub output: Output,
    pub iterations_done: usize,
}

impl<O: MonteCarloOutput> Chunk<O> {
    pub fn new() -> Self {
        Self {
            output: O::new(),
            iterations_done: 0,
        }
    }

    pub fn merge(&mut self, other: &Self) {
        self.output.merge(&other.output);
        self.iterations_done += other.iterations_done;
    }
}

pub enum MessageContent<Output: MonteCarloOutput> {
    Chunk(Chunk<Output>),
    Done,
}

pub struct Message<Output: MonteCarloOutput> {
    pub thread_id: usize,
    pub content: MessageContent<Output>,
}
