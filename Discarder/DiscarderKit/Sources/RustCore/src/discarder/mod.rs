mod algorithm;
use algorithm::*;

use crate::{
    deck::Card,
    montecarlo::{MonteCarlo, MonteCarloConfiguration},
    poker::{PokerHandResolver, PokerHandsCount},
    utils::combinations,
};

use super::deck::Deck;
use itertools::Itertools;

#[derive(Clone)]
pub struct Discarder {
    deck: Deck,
    max_hand_size: usize,
    seed: u64,
}

impl Discarder {
    pub fn new(deck: Deck, hand_size: usize, seed: u64) -> Self {
        Self {
            deck,
            max_hand_size: hand_size,
            seed,
        }
    }

    pub fn run(
        &self,
        hand: &[Card],
        max_iterations: usize,
        progress_handler: impl Fn(&DiscardProgress),
    ) -> DiscardResult {
        let hand_size = hand.len();

        if hand_size >= self.max_hand_size {
            // No need to draw anything, just count the hands
            let mut count = PokerHandsCount::default();
            PokerHandResolver::poker_hands(hand, &mut count);
            return DiscardResult::new(count, 1);
        }

        let combinations =
            combinations(self.deck.cards.len(), self.max_hand_size - hand_size);

        let max_combinations = 30_000;

        if let Some(combinations) = combinations {
            if combinations <= max_combinations {
                println!("Combinations: {}", combinations);
                return self.run_combinations(hand);
            } else {
                println!(
                    "Too many combinations ({} > {}), doing montecarlo",
                    combinations, max_combinations
                );
            }
        } else {
            println!("Too many combinations, not fitting in usize");
        }

        self.run_montecarlo(hand, max_iterations, progress_handler)
    }

    fn run_combinations(&self, hand: &[Card]) -> DiscardResult {
        let hand_size = hand.len();
        assert!(hand_size < self.max_hand_size);

        let cards_to_draw = std::cmp::min(
            self.max_hand_size - hand_size,
            self.deck.cards.len(),
        );

        let mut result = PokerHandsCount::default();
        let mut drawn_hand = vec![Card::invalid(); hand_size + cards_to_draw];

        // Copy initial hand
        drawn_hand[..hand_size].copy_from_slice(hand);

        // Iterate over all possible combinations
        let mut iterations = 0;
        for combination in self.deck.cards.iter().combinations(cards_to_draw) {
            // Draw cards according to current combination
            for (i, &card) in combination.iter().enumerate() {
                drawn_hand[hand_size + i] = *card;
            }

            // Count poker hands
            PokerHandResolver::poker_hands(&drawn_hand, &mut result);
            iterations += 1;
        }

        DiscardResult::new(result, iterations)
    }

    fn run_montecarlo(
        &self,
        hand: &[Card],
        max_iterations: usize,
        progress_handler: impl Fn(&DiscardProgress),
    ) -> DiscardResult {
        use std::thread::available_parallelism;

        let factory = DiscarderFactory::new(self.clone(), hand.to_vec());

        let configuration = MonteCarloConfiguration {
            threads: available_parallelism().unwrap().get(),
            chunk_size: 1000000,
        };

        let mut mc = MonteCarlo::new(factory, configuration, self.seed);

        let result = mc.run(max_iterations, |progress| {
            progress_handler(&DiscardProgress::new(progress));
        });

        DiscardResult::from_result(result)
    }
}

#[cfg(test)]
mod tests {
    use crate::poker::PokerHandsCount;

    use super::*;

    #[test]
    fn test_full_draw() {
        perform_test(
            &Discarder::new(Deck::make_standard(), 8, 43),
            "",
            10000,
            10000,
            &[10000, 8865, 4380, 1167, 1020, 758, 609, 29, 6, 0],
        );
    }

    #[test]
    fn test_empty_draw() {
        perform_test(
            &Discarder::new(Deck::make_standard(), 8, 43),
            "AS AS AS AS AS AS AS AS",
            10000,
            1,
            &[1, 1, 1, 1, 0, 1, 1, 1, 0, 0],
        );
    }

    #[test]
    fn test_large_hand() {
        perform_test(
            &Discarder::new(Deck::make_standard(), 8, 43),
            "AS AS AS AS AS AS AS AS AS AS AS AS",
            10000,
            1,
            &[1, 1, 1, 1, 0, 1, 1, 1, 0, 0],
        );
    }

    #[test]
    fn test_straight_draw() {
        perform_test(
            &Discarder::new(Deck::make_standard(), 8, 43),
            "2S 3S 4S 5S",
            10000,
            10000,
            &[10000, 8784, 4077, 1093, 5026, 6940, 514, 32, 1479, 0],
        );
    }

    #[test]
    fn test_draw_one() {
        perform_test(
            &Discarder::new(Deck::make_standard(), 8, 43),
            "2S 3S 4S 5S 6S 7S 8S",
            10000,
            52,
            &[52, 28, 0, 0, 52, 52, 0, 0, 52, 0],
        );
    }

    #[test]
    fn test_draw_small() {
        perform_test(
            &Discarder::new(Deck::make_standard(), 8, 43),
            "AS KH 5S TC 6D",
            30000,
            22100,
            &[22100, 18516, 7220, 1492, 1008, 286, 480, 20, 1, 0],
        );
    }

    #[test]
    fn test_small_deck() {
        let deck = Deck::new(&Card::make_hand("2S 3S").unwrap());

        perform_test(
            &Discarder::new(deck, 8, 43),
            "AS KH 3H TC 2D",
            10000,
            1,
            &[1, 1, 1, 0, 0, 0, 0, 0, 0, 0],
        );
    }

    #[test]
    fn test_empty_deck() {
        let deck = Deck::new(&[]);

        perform_test(
            &Discarder::new(deck, 8, 43),
            "AS KH 3H TC 2D",
            10000,
            1,
            &[1, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        );
    }

    #[test]
    fn test_empty_hand_empty_deck() {
        let deck = Deck::new(&[]);
        perform_test(
            &Discarder::new(deck, 8, 43),
            "",
            10000,
            1,
            &[0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        );
    }

    fn perform_test(
        discarder: &Discarder,
        hand_string: &str,
        max_iterations: usize,
        expected_iterations: usize,
        expected_result: &[i64],
    ) {
        let hand = Card::make_hand(hand_string).unwrap();

        let result = discarder.run(&hand, max_iterations, |_progress| {
            // println!("Result: {:?}", result);
        });

        println!("Final Result: {:?}", result);

        assert_eq!(result.iterations, expected_iterations);
        assert_eq!(result.count, PokerHandsCount::from_array(expected_result));
    }
}
