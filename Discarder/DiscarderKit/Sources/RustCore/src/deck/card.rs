use super::rank::Rank;
use super::suit::Suit;

#[derive(Debug, Clone, Copy, Eq, PartialEq)]
pub struct Card {
    pub rank: Rank,
    pub suit: Suit,
}

impl Card {
    pub fn invalid() -> Self {
        Self {
            rank: Rank { value: 0 },
            suit: Suit { value: 5 },
        }
    }
}

impl Card {
    pub fn new(rank: Rank, suit: Suit) -> Self {
        Self { rank, suit }
    }

    pub fn from_str(s: &str) -> Option<Self> {
        if s.len() != 2 {
            return None;
        }

        let rank_char = s.chars().nth(0)?;
        let suit_char = s.chars().nth(1)?;

        let rank_value = Rank::from_char(rank_char)?;
        let suit_value = Suit::from_char(suit_char)?;

        Some(Card {
            rank: Rank { value: rank_value },
            suit: Suit { value: suit_value },
        })
    }

    pub fn make_hand(s: &str) -> Option<Vec<Self>> {
        let cards: Vec<Option<Card>> = s
            .split_whitespace()
            .map(|card_str| Card::from_str(card_str))
            .collect();

        if cards.iter().any(|card| card.is_none()) {
            return None;
        }

        Some(cards.into_iter().map(|card| card.unwrap()).collect())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_card_from_str() {
        let card = Card::from_str("3H").unwrap();
        assert_eq!(card.rank.value, 3);
        assert_eq!(card.suit.value, 0);

        let card = Card::from_str("JS").unwrap();
        assert_eq!(card.rank.value, 11);
        assert_eq!(card.suit.value, 3);

        assert!(Card::from_str("").is_none());
        assert!(Card::from_str("XH").is_none());
        assert!(Card::from_str("3X").is_none());
    }

    #[test]
    fn test_make_hand() {
        let hand = Card::make_hand("2H 3D 4C 5S 7H").unwrap();
        assert_eq!(hand.len(), 5);
        assert_eq!(hand[0].rank.value, 2);
        assert_eq!(hand[0].suit.value, 0);
        assert_eq!(hand[1].rank.value, 3);
        assert_eq!(hand[1].suit.value, 1);
        assert_eq!(hand[2].rank.value, 4);
        assert_eq!(hand[2].suit.value, 2);
        assert_eq!(hand[3].rank.value, 5);
        assert_eq!(hand[3].suit.value, 3);
        assert_eq!(hand[4].rank.value, 7);
        assert_eq!(hand[4].suit.value, 0);

        assert_eq!(Card::make_hand(""), Some(vec![]));
        assert!(Card::make_hand("2H 3D XC").is_none());
        assert!(Card::make_hand("2H 3D 4X").is_none());
    }
}
