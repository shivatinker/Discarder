#[derive(
    Debug, Clone, Copy, PartialEq, Eq, Hash, strum::EnumIter, strum::EnumCount,
)]
#[repr(u8)]
pub enum PokerHand {
    HighCard = 0,
    OnePair = 1,
    TwoPair = 2,
    ThreeOfAKind = 3,
    Straight = 4,
    Flush = 5,
    FullHouse = 6,
    FourOfAKind = 7,
    StraightFlush = 8,
    RoyalFlush = 9,
}

impl PokerHand {
    #[inline]
    pub const fn raw_value(self) -> usize {
        self as usize
    }
}
