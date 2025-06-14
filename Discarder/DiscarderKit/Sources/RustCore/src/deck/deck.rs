use super::card::Card;
use super::rank::Rank;
use super::suit::Suit;

#[derive(Clone)]
pub struct Deck {
    pub cards: Vec<Card>,
}

impl Deck {
    #[inline]
    pub fn sample_draw(&self, rng: &mut impl rand::Rng, out: &mut [Card]) {
        assert!(out.len() <= self.cards.len());

        let deck_size = self.cards.len();
        let draw_size = out.len();

        // Use reservoir sampling algorithm for efficient random selection without allocations
        for i in 0..draw_size {
            out[i] = self.cards[i];
        }

        // For each remaining card, decide whether to include it
        for i in draw_size..deck_size {
            let j = rng.gen_range(0..=i);

            if j < draw_size {
                out[j] = self.cards[i];
            }
        }
    }
    
    pub fn new(cards: &[Card]) -> Self {
        Self { cards: cards.to_vec() }
    }

    pub fn make_standard() -> Self {
        let mut cards = Vec::with_capacity(52); // Pre-allocate exact capacity

        for rank in Rank::iter() {
            for suit in Suit::iter() {
                cards.push(Card::new(rank, suit));
            }
        }

        Self { cards }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_new_deck_has_52_cards() {
        let deck = Deck::make_standard();
        assert_eq!(deck.cards.len(), 52);
    }

    #[test]
    fn test_deck_contains_all_cards() {
        let deck = Deck::make_standard();

        // Check we have exactly 13 ranks and 4 suits
        let mut rank_counts = [0; 15]; // index 2-14
        let mut suit_counts = [0; 4]; // index 0-3

        for card in &deck.cards {
            rank_counts[card.rank.value as usize] += 1;
            suit_counts[card.suit.value as usize] += 1;
        }

        // Each rank should appear exactly 4 times (once per suit)
        for rank in 2..=14 {
            assert_eq!(
                rank_counts[rank], 4,
                "Rank {} should appear 4 times",
                rank
            );
        }

        // Each suit should appear exactly 13 times (once per rank)
        for suit in 0..4 {
            assert_eq!(
                suit_counts[suit], 13,
                "Suit {} should appear 13 times",
                suit
            );
        }
    }

    #[test]
    fn test_sample_draw() {
        use rand::SeedableRng;
        use rand_pcg::Pcg64;

        let deck = Deck::make_standard();
        let mut rng = Pcg64::seed_from_u64(42);

        for size in 0..=52 {
            let mut result = vec![Card::invalid(); size];
            deck.sample_draw(&mut rng, &mut result);
            assert_eq!(result.len(), size);

            // Check no duplicates
            for i in 0..result.len() {
                for j in i + 1..result.len() {
                    assert_ne!(
                        result[i], result[j],
                        "Found duplicate cards in sample"
                    );
                }
            }
        }
    }
}
