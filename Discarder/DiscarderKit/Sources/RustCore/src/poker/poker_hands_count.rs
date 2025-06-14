use crate::poker::poker_hand::PokerHand;
use crate::montecarlo::MonteCarloOutput;
use std::ops::{Index, IndexMut};
use strum::EnumCount;

#[derive(Debug, Clone, Default, PartialEq, Eq)]
pub struct PokerHandsCount {
    counts: [i64; PokerHand::COUNT],
}

impl PokerHandsCount {
    pub fn new() -> Self {
        PokerHandsCount {
            counts: [0; PokerHand::COUNT],
        }
    }

    /// Create from a C array (slice)
    pub fn from_array(array: &[i64]) -> Self {
        let mut counts = [0i64; PokerHand::COUNT];
        let len = array.len().min(PokerHand::COUNT);
        counts[..len].copy_from_slice(&array[..len]);
        PokerHandsCount { counts }
    }

    /// Copy counts to a C array
    pub fn to_array(&self, array: &mut [i64]) {
        let len = array.len().min(PokerHand::COUNT);
        array[..len].copy_from_slice(&self.counts[..len]);
    }

    pub fn iter(&self) -> impl Iterator<Item = &i64> {
        self.counts.iter()
    }

    pub fn merge(&mut self, other: &Self) {
        for (i, &count) in other.counts.iter().enumerate() {
            self.counts[i] += count;
        }
    }
}

impl Index<PokerHand> for PokerHandsCount {
    type Output = i64;

    fn index(&self, hand: PokerHand) -> &Self::Output {
        &self.counts[hand.raw_value()]
    }
}

impl IndexMut<PokerHand> for PokerHandsCount {
    fn index_mut(&mut self, hand: PokerHand) -> &mut Self::Output {
        &mut self.counts[hand.raw_value()]
    }
}

impl MonteCarloOutput for PokerHandsCount {
    fn new() -> Self {
        Self::new()
    }

    fn merge(&mut self, other: &Self) {
        self.merge(other);
    }
}
