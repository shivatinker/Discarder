#[derive(Debug, Clone, Copy, Eq, PartialEq, Default)]
pub struct Suit {
    pub value: u8, // From 0 to 3
}

impl Suit {
    pub fn iter() -> impl Iterator<Item = Suit> {
        (0..4).map(|value| Suit { value })
    }
}

impl Suit {
    pub fn from_char(c: char) -> Option<u8> {
        match c {
            'H' => Some(0),
            'D' => Some(1),
            'C' => Some(2),
            'S' => Some(3),
            _ => None,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_suit_from_char() {
        assert_eq!(Suit::from_char('H'), Some(0));
        assert_eq!(Suit::from_char('D'), Some(1));
        assert_eq!(Suit::from_char('C'), Some(2));
        assert_eq!(Suit::from_char('S'), Some(3));
        assert_eq!(Suit::from_char('X'), None);
    }
}
