#[cfg(test)]
use super::*;
use rand::{Rng, SeedableRng};

#[derive(Clone)]
pub struct PiEstimator {
    rng: rand::rngs::StdRng,
}

impl PiEstimator {
    pub fn new_with_seed(seed: u64) -> Self {
        Self {
            rng: rand::rngs::StdRng::seed_from_u64(seed),
        }
    }
}

pub struct PiEstimatorFactory;

impl MonteCarloAlgorithmFactory for PiEstimatorFactory {
    type Algorithm = PiEstimator;

    fn make(&self, seed: u64) -> Self::Algorithm {
        PiEstimator::new_with_seed(seed)
    }
}

#[derive(Debug, Clone)]
pub struct PiResult {
    pub points_inside_circle: u64,
    pub total_points: u64,
}

impl PiResult {
    pub fn estimate_pi(&self) -> f64 {
        if self.total_points == 0 {
            0.0
        } else {
            4.0 * (self.points_inside_circle as f64)
                / (self.total_points as f64)
        }
    }
}

impl MonteCarloOutput for PiResult {
    fn new() -> Self {
        Self {
            points_inside_circle: 0,
            total_points: 0,
        }
    }

    fn merge(&mut self, other: &Self) {
        self.points_inside_circle += other.points_inside_circle;
        self.total_points += other.total_points;
    }
}

impl MonteCarloAlgorithm for PiEstimator {
    type Output = PiResult;

    fn sample(&mut self, output: &mut Self::Output) {
        let x: f64 = self.rng.gen_range(0.0..1.0);
        let y: f64 = self.rng.gen_range(0.0..1.0);

        // Check if point is inside unit circle
        if x * x + y * y <= 1.0 {
            output.points_inside_circle += 1;
        }
        output.total_points += 1;
    }
}

#[test]
fn test_pi_estimation_seeded() {
    let factory = PiEstimatorFactory;
    let config = MonteCarloConfiguration {
        threads: 8,
        chunk_size: 100,
    };

    // Test with a specific seed for reproducible results
    let mut monte_carlo = MonteCarlo::new(factory, config, 12345);
    monte_carlo.run(5000, |progress| {
        println!("Progress: {:.1}%", progress.fraction_completed * 100.0);
    });

    let pi_estimate = monte_carlo.chunk.output.estimate_pi();
    let total_iterations = monte_carlo.chunk.output.total_points;

    println!("Seeded Pi estimate: {}", pi_estimate);
    println!("Seeded Total iterations performed: {}", total_iterations);
    println!("Seeded Expected iterations: 5000");
    println!(
        "Seeded Error: {}",
        (pi_estimate - std::f64::consts::PI).abs()
    );

    // Verify we performed exactly the expected number of iterations
    assert_eq!(total_iterations, 5000);

    // Pi should be approximately 3.14159, allow for Monte Carlo variance
    assert!((pi_estimate - std::f64::consts::PI).abs() < 0.1);
}
