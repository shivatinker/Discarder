#[derive(Debug, Clone, Copy, Eq, PartialEq, Default)]
pub struct Rank {
    pub value: u8, // From 2 to 14
}

impl Rank {
    pub fn iter() -> impl Iterator<Item = Rank> {
        (2..=14).map(|value| Rank { value })
    }
}

impl Rank {
    pub fn from_char(c: char) -> Option<u8> {
        match c {
            '2'..='9' => c.to_digit(10).map(|n| n as u8),
            'T' => Some(10),
            'J' => Some(11),
            'Q' => Some(12),
            'K' => Some(13),
            'A' => Some(14),
            _ => None,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_rank_from_char() {
        assert_eq!(Rank::from_char('3'), Some(3));
        assert_eq!(Rank::from_char('T'), Some(10));
        assert_eq!(Rank::from_char('J'), Some(11));
        assert_eq!(Rank::from_char('Q'), Some(12));
        assert_eq!(Rank::from_char('K'), Some(13));
        assert_eq!(Rank::from_char('A'), Some(14));
        assert_eq!(Rank::from_char('X'), None);
    }
}
