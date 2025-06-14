pub trait MonteCarloAlgorithm: Send {
    type Output: MonteCarloOutput;

    fn sample(&mut self, output: &mut Self::Output);
}

pub trait MonteCarloAlgorithmFactory: Send + 'static {
    type Algorithm: MonteCarloAlgorithm;

    fn make(&self, seed: u64) -> Self::Algorithm;
}

pub trait MonteCarloOutput: Send + Clone {
    fn new() -> Self;
    fn merge(&mut self, other: &Self);
}
