use std::cmp::max;

use rand::SeedableRng;

use crate::{
    deck::Card,
    discarder::Discarder,
    montecarlo::{
        Chunk, MonteCarloAlgorithm, MonteCarloAlgorithmFactory, Progress,
    },
    poker::PokerHandsCount,
};

#[derive(Debug)]
pub struct DiscardProgress<'a> {
    pub count: &'a PokerHandsCount,
    pub iterations: usize,
    pub fraction_completed: f64,
}

impl<'a> DiscardProgress<'a> {
    pub fn new(result: &'a Progress<DiscarderAlgorithm>) -> Self {
        Self {
            count: &result.chunk.output,
            iterations: result.chunk.iterations_done,
            fraction_completed: result.fraction_completed,
        }
    }
}

#[derive(Debug)]
pub struct DiscardResult {
    pub count: PokerHandsCount,
    pub iterations: usize,
}

impl DiscardResult {
    pub fn from_result(result: Chunk<PokerHandsCount>) -> Self {
        Self {
            count: result.output,
            iterations: result.iterations_done,
        }
    }

    pub fn new(count: PokerHandsCount, iterations: usize) -> Self {
        Self { count, iterations }
    }
}

pub struct DiscarderFactory {
    discarder: Discarder,
    hand: Vec<Card>,
}

impl DiscarderFactory {
    pub fn new(discarder: Discarder, hand: Vec<Card>) -> Self {
        Self { discarder, hand }
    }
}

impl MonteCarloAlgorithmFactory for DiscarderFactory {
    type Algorithm = DiscarderAlgorithm;

    fn make(&self, seed: u64) -> DiscarderAlgorithm {
        let initial_hand_size = self.hand.len();

        assert!(
            self.discarder.deck.cards.len()
                >= self.discarder.max_hand_size - initial_hand_size
        );

        let size = max(self.discarder.max_hand_size, initial_hand_size);
        let mut drawn_hand = vec![Card::invalid(); size];
        drawn_hand[..initial_hand_size].copy_from_slice(&self.hand);

        DiscarderAlgorithm {
            discarder: self.discarder.clone(),
            initial_hand_size,
            drawn_hand,
            rng: rand_pcg::Pcg64::seed_from_u64(seed),
        }
    }
}

pub struct DiscarderAlgorithm {
    discarder: Discarder,
    initial_hand_size: usize,
    drawn_hand: Vec<Card>,
    rng: rand_pcg::Pcg64,
}

impl MonteCarloAlgorithm for DiscarderAlgorithm {
    type Output = PokerHandsCount;

    fn sample(&mut self, output: &mut Self::Output) {
        assert!(self.discarder.max_hand_size > self.initial_hand_size);

        let draw_slice = &mut self.drawn_hand
            [self.initial_hand_size..self.discarder.max_hand_size];
        self.discarder.deck.sample_draw(&mut self.rng, draw_slice);

        // Count poker hands in the complete drawn hand
        self.count_poker_hands(&self.drawn_hand, output);
    }
}

impl DiscarderAlgorithm {
    fn count_poker_hands(&self, hand: &[Card], output: &mut PokerHandsCount) {
        use crate::poker::PokerHandResolver;
        PokerHandResolver::poker_hands(hand, output);
    }
}
