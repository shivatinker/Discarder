use crate::deck::Card;
use crate::poker::poker_hand::PokerHand;
use crate::poker::poker_hands_count::PokerHandsCount;

pub struct PokerHandResolver;

impl PokerHandResolver {
    pub fn poker_hands(hand: &[Card], hands: &mut PokerHandsCount) {
        if hand.is_empty() {
            return;
        }

        if hand.contains(&Card::invalid()) {
            panic!("Invalid card detected!")
        }

        hands[PokerHand::HighCard] += 1;

        // Single pass through cards - count everything at once
        let mut rank_counts = [0u8; 15];
        let mut suit_counts = [0u8; 4];
        let mut suit_rank_bits = [0u16; 4]; // Bit representation for each suit's ranks

        for card in hand {
            let rank = card.rank.value as usize;
            let suit = card.suit.value as usize;

            rank_counts[rank] += 1;
            suit_counts[suit] += 1;
            suit_rank_bits[suit] |= 1u16 << rank;
        }

        // Analyze rank patterns in single pass
        let mut pair_count = 0u8;
        let mut three_count = 0u8;
        let mut four_count = 0u8;
        let mut five_count = 0u8;

        // Optimized rank counting - skip empty slots
        for &count in &rank_counts[2..=14] {
            // Use lookup table approach for better branch prediction
            match count {
                2 => pair_count += 1,
                3 => three_count += 1,
                4 => four_count += 1,
                c if c >= 5 => five_count += 1,
                _ => {}
            }
        }

        // Compute poker hands with minimal branching
        let has_pair = pair_count > 0
            || three_count > 0
            || four_count > 0
            || five_count > 0;
        let total_groups = pair_count + three_count + four_count + five_count;
        let has_two_pair =
            total_groups >= 2 || four_count > 0 || five_count > 0;
        let has_three = three_count > 0 || four_count > 0 || five_count > 0;
        let has_four = four_count > 0 || five_count > 0;
        let has_full_house = (three_count > 0 && pair_count > 0)
            || (four_count > 0 && (pair_count > 0 || three_count > 0))
            || three_count >= 2
            || four_count >= 2
            || five_count > 0;

        // Set flags with minimal branches
        if has_pair {
            hands[PokerHand::OnePair] += 1;
        }
        if has_two_pair {
            hands[PokerHand::TwoPair] += 1;
        }
        if has_three {
            hands[PokerHand::ThreeOfAKind] += 1;
        }
        if has_four {
            hands[PokerHand::FourOfAKind] += 1;
        }
        if has_full_house {
            hands[PokerHand::FullHouse] += 1;
        }

        // Check for flush using bit manipulation
        let has_flush = suit_counts[0] >= 5
            || suit_counts[1] >= 5
            || suit_counts[2] >= 5
            || suit_counts[3] >= 5;
        if has_flush {
            hands[PokerHand::Flush] += 1;
        }

        // Optimized straight detection using bit operations
        let has_straight = Self::has_straight_bits(&rank_counts);
        if has_straight {
            hands[PokerHand::Straight] += 1;
        }

        // Optimized straight flush detection
        let straight_flush_result =
            Self::check_straight_flush_bits(&suit_rank_bits, &suit_counts);
        if straight_flush_result > 0 {
            hands[PokerHand::StraightFlush] += 1;

            // Check for royal flush (bit 2 indicates royal)
            if straight_flush_result & 2 != 0 {
                hands[PokerHand::RoyalFlush] += 1;
            }
        }
    }

    // Optimized straight detection using bit manipulation
    #[inline]
    fn has_straight_bits(rank_counts: &[u8; 15]) -> bool {
        // Convert rank counts to bit representation
        let mut rank_bits = 0u16;
        for i in 2..=14 {
            if rank_counts[i] > 0 {
                rank_bits |= 1u16 << i;
            }
        }

        // Check for 5 consecutive bits using bit manipulation
        // Patterns for straights: 0b11111 shifted to different positions
        const STRAIGHT_MASKS: [u16; 10] = [
            0b11111 << 2,            // 2-3-4-5-6
            0b11111 << 3,            // 3-4-5-6-7
            0b11111 << 4,            // 4-5-6-7-8
            0b11111 << 5,            // 5-6-7-8-9
            0b11111 << 6,            // 6-7-8-9-T
            0b11111 << 7,            // 7-8-9-T-J
            0b11111 << 8,            // 8-9-T-J-Q
            0b11111 << 9,            // 9-T-J-Q-K
            0b11111 << 10,           // T-J-Q-K-A
            0b1111 << 2 | 0b1 << 14, // A-2-3-4-5 (wheel)
        ];

        STRAIGHT_MASKS
            .iter()
            .any(|&mask| (rank_bits & mask) == mask)
    }

    // Optimized straight flush detection returning both straight flush and royal flush info
    #[inline]
    fn check_straight_flush_bits(
        suit_rank_bits: &[u16; 4],
        suit_counts: &[u8; 4],
    ) -> u8 {
        // Only check suits that have 5+ cards
        for suit in 0..4 {
            if suit_counts[suit] < 5 {
                continue;
            }

            let bits = suit_rank_bits[suit];

            // Check straight flush patterns
            const STRAIGHT_MASKS: [u16; 9] = [
                0b11111 << 2,            // 2-3-4-5-6
                0b11111 << 3,            // 3-4-5-6-7
                0b11111 << 4,            // 4-5-6-7-8
                0b11111 << 5,            // 5-6-7-8-9
                0b11111 << 6,            // 6-7-8-9-T
                0b11111 << 7,            // 7-8-9-T-J
                0b11111 << 8,            // 8-9-T-J-Q
                0b11111 << 9,            // 9-T-J-Q-K
                0b1111 << 2 | 0b1 << 14, // A-2-3-4-5 (wheel)
            ];

            // Check royal flush first (T-J-Q-K-A)
            const ROYAL_MASK: u16 = 0b11111 << 10;
            if (bits & ROYAL_MASK) == ROYAL_MASK {
                return 3; // Both straight flush and royal flush
            }

            // Check other straight flushes
            for &mask in &STRAIGHT_MASKS {
                if (bits & mask) == mask {
                    return 1; // Straight flush only
                }
            }
        }

        0 // No straight flush
    }
}

// MARK: - Tests

#[cfg(test)]
mod tests {
    use super::*;
    use std::collections::HashSet;
    use strum::IntoEnumIterator;
    use PokerHand::*;

    #[test]
    fn test_high_card() {
        assert_poker_hands("2S", &[HighCard]);
        assert_poker_hands("AH", &[HighCard]);
        assert_poker_hands("2S 5H 7C 9D JH", &[HighCard]);
    }

    #[test]
    fn test_one_pair() {
        assert_poker_hands("2S 2H", &[HighCard, OnePair]);
        assert_poker_hands("AS AH", &[HighCard, OnePair]);
        assert_poker_hands("KS KH 3C", &[HighCard, OnePair]);
    }

    #[test]
    fn test_two_pair() {
        assert_poker_hands("2S 2H 3C 3D", &[HighCard, OnePair, TwoPair]);
        assert_poker_hands("AS AH KC KD", &[HighCard, OnePair, TwoPair]);
        assert_poker_hands("7S 7H QC QD 5H", &[HighCard, OnePair, TwoPair]);
    }

    #[test]
    fn test_three_of_a_kind() {
        assert_poker_hands("2S 2H 2C", &[HighCard, OnePair, ThreeOfAKind]);
        assert_poker_hands("AS AH AC", &[HighCard, OnePair, ThreeOfAKind]);
        assert_poker_hands(
            "KS KH KC 5D 7H",
            &[HighCard, OnePair, ThreeOfAKind],
        );
    }

    #[test]
    fn test_straight() {
        assert_poker_hands("2S 3H 4C 5D 6H", &[HighCard, Straight]);
        assert_poker_hands("TS JH QC KD AH", &[HighCard, Straight]);
        assert_poker_hands("AS 2H 3C 4D 5H", &[HighCard, Straight]); // Ace-low straight
    }

    #[test]
    fn test_flush() {
        assert_poker_hands("2S 5S 7S 9S JS", &[HighCard, Flush]);
        assert_poker_hands("AH 3H 6H 9H QH", &[HighCard, Flush]);
    }

    #[test]
    fn test_full_house() {
        assert_poker_hands(
            "2S 2H 2C 3D 3H",
            &[HighCard, OnePair, TwoPair, ThreeOfAKind, FullHouse],
        );
        assert_poker_hands(
            "AS AH AC KD KH",
            &[HighCard, OnePair, TwoPair, ThreeOfAKind, FullHouse],
        );
    }

    #[test]
    fn test_four_of_a_kind() {
        assert_poker_hands(
            "2S 2H 2C 2D",
            &[HighCard, OnePair, TwoPair, ThreeOfAKind, FourOfAKind], // Quads contain two pair
        );
        assert_poker_hands(
            "AS AH AC AD",
            &[HighCard, OnePair, TwoPair, ThreeOfAKind, FourOfAKind], // Quads contain two pair
        );
        assert_poker_hands(
            "KS KH KC KD 5H",
            &[HighCard, OnePair, TwoPair, ThreeOfAKind, FourOfAKind], // Quads contain two pair
        );
    }

    #[test]
    fn test_straight_flush() {
        assert_poker_hands(
            "2S 3S 4S 5S 6S",
            &[HighCard, Flush, Straight, StraightFlush],
        );
        assert_poker_hands(
            "7H 8H 9H TH JH",
            &[HighCard, Flush, Straight, StraightFlush],
        );
    }

    #[test]
    fn test_royal_flush() {
        assert_poker_hands(
            "TS JS QS KS AS",
            &[HighCard, Flush, Straight, StraightFlush, RoyalFlush],
        );
        assert_poker_hands(
            "TH JH QH KH AH",
            &[HighCard, Flush, Straight, StraightFlush, RoyalFlush],
        );
    }

    // MARK: - Edge Cases

    #[test]
    fn test_empty_hand() {
        assert_poker_hands("", &[]);
    }

    #[test]
    fn test_single_card() {
        assert_poker_hands("AS", &[HighCard]);
        assert_poker_hands("2C", &[HighCard]);
    }

    #[test]
    fn test_non_consecutive_cards() {
        assert_poker_hands("2S 4H 6C 8D TH", &[HighCard]);
        assert_poker_hands("AS 3H 5C 7D 9H", &[HighCard]);
    }

    #[test]
    fn test_almost_straight() {
        assert_poker_hands("2S 3H 4C 5D 7H", &[HighCard]); // Missing 6
        assert_poker_hands("TS JH QC AD 2H", &[HighCard]); // Gap between K and A
    }

    #[test]
    fn test_almost_flush() {
        assert_poker_hands("2S 5S 7S 9S JH", &[HighCard]); // 4 spades + 1 heart
    }

    // MARK: - Larger Hands (6-8 cards)

    #[test]
    fn test_six_card_hand() {
        // Contains both a flush and a straight
        assert_poker_hands(
            "2S 3S 4S 5S 6S 7H",
            &[HighCard, Flush, Straight, StraightFlush],
        );

        // Contains full house
        assert_poker_hands(
            "AS AH AC KD KH QC",
            &[HighCard, OnePair, TwoPair, ThreeOfAKind, FullHouse],
        );

        // Contains four of a kind
        assert_poker_hands(
            "2S 2H 2C 2D 5H 7C",
            &[HighCard, OnePair, TwoPair, ThreeOfAKind, FourOfAKind], // Quads contain two pair
        );
    }

    #[test]
    fn test_seven_card_hand() {
        // Contains multiple pairs
        assert_poker_hands(
            "2S 2H 3C 3D 4H 4S 5C",
            &[HighCard, OnePair, TwoPair],
        );

        // Contains straight flush
        assert_poker_hands(
            "2S 3S 4S 5S 6S 7H 8C",
            &[HighCard, Flush, Straight, StraightFlush],
        );

        // Contains full house with extra cards
        assert_poker_hands(
            "AS AH AC KD KH QC JH",
            &[HighCard, OnePair, TwoPair, ThreeOfAKind, FullHouse],
        );
    }

    #[test]
    fn test_eight_card_hand() {
        // Contains royal flush with extra cards
        assert_poker_hands(
            "TS JS QS KS AS 2H 3C 4D",
            &[HighCard, Flush, Straight, StraightFlush, RoyalFlush],
        );

        // Contains multiple different hands
        assert_poker_hands(
            "2S 2H 3C 3D 4H 4S 5C 5D",
            &[HighCard, OnePair, TwoPair],
        );

        // Contains four of a kind with extra cards
        assert_poker_hands(
            "AS AH AC AD KS KH QC JD",
            &[
                HighCard,
                OnePair,
                TwoPair,
                ThreeOfAKind,
                FullHouse,
                FourOfAKind,
            ],
        );

        // Complex hand with flush and pairs
        assert_poker_hands(
            "2S 3S 4S 5S 7S 2H 3H 4H",
            &[HighCard, OnePair, TwoPair, Flush],
        );
    }

    // MARK: - Special Straight Cases

    #[test]
    fn test_ace_low_straight() {
        assert_poker_hands("AS 2H 3C 4D 5S", &[HighCard, Straight]);
    }

    #[test]
    fn test_ace_high_straight() {
        assert_poker_hands("TS JH QC KD AS", &[HighCard, Straight]);
    }

    #[test]
    fn test_ace_low_straight_flush() {
        assert_poker_hands(
            "AS 2S 3S 4S 5S",
            &[HighCard, Flush, Straight, StraightFlush],
        );
    }

    #[test]
    fn test_not_ace_wrap_around_straight() {
        // Q, K, A, 2, 3 is not a valid straight
        assert_poker_hands("QS KH AC 2D 3S", &[HighCard]);
    }

    #[test]
    fn test_straight_and_flush_but_not_straight_flush() {
        // Contains straight (2-3-4-5-6) and flush (7H 8H JH QH KH) but not straight flush
        // Expected: OnePair (two 4s), Straight, Flush, but NOT StraightFlush
        assert_poker_hands(
            "2H 3D 4C 5S 6C 4H 7H 8H JH QH KH",
            &[HighCard, OnePair, Straight, Flush],
        );
    }

    #[test]
    fn test_royal_straight_and_flush_but_not_royal_flush() {
        // Contains royal straight (T-J-Q-K-A) in mixed suits and separate flush
        // Straight: TH JD QC KS AH (royal straight in mixed suits)
        // Flush: 2C 3C 5C 7C 9C (5 clubs, not royal)
        // Expected: Straight, Flush, but NOT StraightFlush, NOT RoyalFlush
        assert_poker_hands(
            "TH JD QC KS AH 2C 3C 5C 7C 9C",
            &[HighCard, Straight, Flush],
        );

        // Another case: royal straight + different flush (no overlapping cards)
        // Straight: TC JH QD KH AS (royal straight in mixed suits)
        // Flush: 4S 6S 8S 9S AS (5 spades, shares only the Ace)
        assert_poker_hands(
            "TC JH QD KH AS 4S 6S 8S 9S",
            &[HighCard, Straight, Flush],
        );
    }

    // MARK: - Tricky Edge Cases with Many Cards

    #[test]
    fn test_multiple_straights_and_flushes() {
        // Hand with multiple possible straights and flushes
        // Straights: A-2-3-4-5 (ace low) AND 3-4-5-6-7 AND 5-6-7-8-9
        // Flush: 7+ hearts
        assert_poker_hands(
            "AH 2H 3H 4H 5H 6H 7H 8C 9D",
            &[HighCard, Straight, Flush, StraightFlush],
        );
    }

    #[test]
    fn test_multiple_pairs_and_three_of_kinds() {
        // Complex hand: AAA 222 33 44 5 (two three-of-kinds, two pairs)
        // Unexpectedly this also forms a straight: A-2-3-4-5!
        // Should detect: OnePair, TwoPair, ThreeOfAKind, FullHouse, Straight
        assert_poker_hands(
            "AS AH AC 2S 2H 2C 3S 3H 4D 4C 5H",
            &[
                HighCard,
                OnePair,
                TwoPair,
                ThreeOfAKind,
                FullHouse,
                Straight,
            ],
        );
    }

    #[test]
    fn test_four_of_kind_with_additional_pairs() {
        // AAAA BB CC D (four-of-kind + two pairs)
        // Should include FullHouse since four-of-kind + any pair = full house
        assert_poker_hands(
            "AS AH AC AD 2S 2H 3C 3D 5H",
            &[
                HighCard,
                OnePair,
                TwoPair,
                ThreeOfAKind,
                FullHouse,
                FourOfAKind,
            ],
        );
    }

    #[test]
    fn test_double_flush_different_suits() {
        // 5+ hearts AND 5+ spades (but no straight flush)
        // Using truly non-consecutive ranks: 2, 4, 6, 8, J, 3, 9, Q, K, A
        assert_poker_hands(
            "2H 4H 6H 8H JH 3S 9S QS KS AS",
            &[HighCard, Flush], // Just flush, no straight
        );
    }

    #[test]
    fn test_almost_straight_flush_with_gaps() {
        // Has flush (hearts) but with gaps in the straight flush
        // 2H 3H [gap] 6H 7H 8H 9H JH 4C
        // Flush: 2H 3H 6H 7H 8H 9H JH (hearts)
        // Straight: 6-7-8-9-T missing T, so no straight in hearts
        // Mixed straight: 4C [gap at 5] 6H 7H 8H 9H - no 5, so no straight
        assert_poker_hands(
            "2H 3H 6H 7H 8H 9H JH 4C",
            &[HighCard, Flush], // Flush but no straight
        );
    }

    #[test]
    fn test_extended_royal_flush() {
        // Royal flush with extra cards: 9H TH JH QH KH AH 2C
        // Should detect royal flush correctly despite extra cards
        assert_poker_hands(
            "9H TH JH QH KH AH 2C",
            &[HighCard, Flush, Straight, StraightFlush, RoyalFlush],
        );
    }

    #[test]
    fn test_wheel_straight_with_extra_aces() {
        // A-2-3-4-5 straight with extra aces: A A 2 3 4 5 6
        // Should detect straight (wheel) and pair (two aces)
        assert_poker_hands(
            "AS AH 2C 3D 4H 5S 6C",
            &[HighCard, OnePair, Straight],
        );
    }

    #[test]
    fn test_broadway_and_wheel_straights() {
        // Has both Broadway (T-J-Q-K-A) and Wheel (A-2-3-4-5) straights
        // A 2 3 4 5 T J Q K (missing one A for both)
        // This should only detect one straight, not both
        assert_poker_hands("AC 2D 3H 4S 5C TH JD QS KH", &[HighCard, Straight]);
    }

    #[test]
    fn test_complex_ten_card_hand() {
        // Complex 10-card hand with multiple overlapping features
        // Royal flush: TS JS QS KS AS
        // Additional pairs: 2H 2C, 7H 7D
        // Extra card: 9C
        assert_poker_hands(
            "TS JS QS KS AS 2H 2C 7H 7D 9C",
            &[
                HighCard,
                OnePair,
                TwoPair,
                Flush,
                Straight,
                StraightFlush,
                RoyalFlush,
            ],
        );
    }

    #[test]
    fn test_quad_aces_with_broadway_straight() {
        // Four aces + Broadway straight using other cards
        // AAAA + TJQK (with one A from the quads completing Broadway)
        assert_poker_hands(
            "AS AH AC AD TS JC QD KH 9S",
            &[
                HighCard,
                OnePair,
                TwoPair,
                ThreeOfAKind,
                FourOfAKind,
                Straight,
            ], // Quads contain two pair
        );
    }

    #[test]
    fn test_multiple_straight_flushes_possible() {
        // Hand that could form multiple straight flushes
        // Hearts: 5H 6H 7H 8H 9H TH (6-7-8-9-T and 5-6-7-8-9)
        // Should detect straight flush (any 5-card sequence counts)
        assert_poker_hands(
            "5H 6H 7H 8H 9H TH 2C",
            &[HighCard, Flush, Straight, StraightFlush],
        );
    }

    #[test]
    fn test_full_house_with_quads() {
        // Hand with four-of-a-kind AND full house
        // AAAA + 222 should be both four-of-kind and full house
        assert_poker_hands(
            "AS AH AC AD 2S 2H 2C",
            &[
                HighCard,
                OnePair,
                TwoPair,
                ThreeOfAKind,
                FullHouse,
                FourOfAKind,
            ],
        );
    }

    #[test]
    fn test_steel_wheel_straight_flush() {
        // A-2-3-4-5 straight flush (steel wheel)
        assert_poker_hands(
            "AS 2S 3S 4S 5S 6H 7C",
            &[HighCard, Flush, Straight, StraightFlush],
        );
    }

    #[test]
    fn test_near_impossible_hand() {
        // Hand with nearly everything: straight flush + full house
        // Royal flush in spades: TS JS QS KS AS
        // Additional: 2H 2C 2D (three 2s)
        // Additional: KH KC (pair of kings, combining with KS for trips)
        assert_poker_hands(
            "TS JS QS KS AS 2H 2C 2D KH KC",
            &[
                HighCard,
                OnePair,
                TwoPair,
                ThreeOfAKind,
                FullHouse,
                Flush,
                Straight,
                StraightFlush,
                RoyalFlush,
            ],
        );
    }

    // MARK: - Extreme Edge Cases

    #[test]
    fn test_overlapping_straight_flushes() {
        // 8-card hand with overlapping straight flushes in hearts
        // Can form: 3-4-5-6-7, 4-5-6-7-8, 5-6-7-8-9
        assert_poker_hands(
            "3H 4H 5H 6H 7H 8H 9H 2C",
            &[HighCard, Flush, Straight, StraightFlush],
        );
    }

    #[test]
    fn test_quad_with_two_pairs() {
        // Four of a kind + two additional pairs: AAAA + 22 + 33
        assert_poker_hands(
            "AS AH AC AD 2S 2H 3C 3D",
            &[
                HighCard,
                OnePair,
                TwoPair,
                ThreeOfAKind,
                FullHouse,
                FourOfAKind,
            ],
        );
    }

    #[test]
    fn test_impossible_poker_scenario() {
        // 13-card hand with maximum complexity
        // Royal flush + quads + full house components
        // Royal: TS JS QS KS AS
        // Quads: 2H 2C 2D 2S
        // Trip: 7H 7C 7D
        // Pair: KH KC (with KS from royal = trip kings)
        assert_poker_hands(
            "TS JS QS KS AS 2H 2C 2D 2S 7H 7C 7D KH",
            &[
                HighCard,
                OnePair,
                TwoPair,
                ThreeOfAKind,
                FullHouse,
                FourOfAKind,
                Flush,
                Straight,
                StraightFlush,
                RoyalFlush,
            ],
        );
    }

    #[test]
    fn test_mixed_wheel_and_broadway() {
        // Hand with both ace-low and ace-high straight potential
        // A-2-3-4-5 wheel + T-J-Q-K-A broadway (sharing the aces)
        assert_poker_hands(
            "AS AH 2C 3D 4H 5S TC JD QH KS",
            &[HighCard, OnePair, Straight], // OnePair from two aces
        );
    }

    // MARK: - Bug Detection Tests

    #[test]
    fn test_single_four_of_kind_contains_two_pair() {
        // AAAA + single cards: quads contain two pair (can select 2A + 2A)
        assert_poker_hands(
            "AS AH AC AD 5C 7D 9H",
            &[HighCard, OnePair, TwoPair, ThreeOfAKind, FourOfAKind], // Quads contain two pair
        );
    }

    #[test]
    fn test_double_four_of_kinds_full_house() {
        // Two four-of-kinds should allow full house formation
        // AAAA + 2222 -> can form AAA22 (full house)
        assert_poker_hands(
            "AS AH AC AD 2S 2H 2C 2D",
            &[
                HighCard,
                OnePair,
                TwoPair,
                ThreeOfAKind,
                FullHouse,
                FourOfAKind,
            ],
        );
    }

    #[test]
    fn test_five_of_a_kind_contains_full_house() {
        // Note: Real poker deck doesn't allow 5 of same rank, but testing edge case logic
        // We'll simulate by manually setting rank_counts[rank] = 5 in the algorithm

        // For now, test realistic scenarios that verify the updated logic works
        assert_poker_hands(
            "AS AH AC AD 2S 2H 2C 2D 3S 3H 3C", // 4A + 4two + 3three
            &[
                HighCard,
                OnePair,
                TwoPair,
                ThreeOfAKind,
                FullHouse,
                FourOfAKind,
            ],
        );

        // Test that the five_count logic paths are reachable
        // (the match arm 5.. should work correctly even though we can't test with real cards)
    }

    #[test]
    fn test_correct_two_pair_scenarios() {
        // These SHOULD have TwoPair
        assert_poker_hands(
            "AS AH 2C 2D 5H", // Two aces + two twos (traditional two pair)
            &[HighCard, OnePair, TwoPair],
        );

        assert_poker_hands(
            "KS KH KC 2S 2H", // Three kings + two twos -> can form KK22+card
            &[HighCard, OnePair, TwoPair, ThreeOfAKind, FullHouse],
        );

        assert_poker_hands(
            "AS AH AC AD 2S 2H", // Four aces + two twos -> can form AA22+card
            &[
                HighCard,
                OnePair,
                TwoPair,
                ThreeOfAKind,
                FullHouse,
                FourOfAKind,
            ],
        );
    }

    #[test]
    fn test_new_logic_verification() {
        // Verify the new interpretation: quads contain two pair
        assert_poker_hands(
            "AS AH AC AD", // Four aces: can form AA + AA (two pair from same rank)
            &[HighCard, OnePair, TwoPair, ThreeOfAKind, FourOfAKind],
        );

        // Verify: no two pair when only one rank with less than 4 cards
        assert_poker_hands(
            "AS AH AC 5D 7H", // Three aces + singles: can form AA but not two pair
            &[HighCard, OnePair, ThreeOfAKind], // No TwoPair
        );
    }

    #[test]
    fn test_six_plus_cards_logic() {
        // Test maximum possible with real deck: 4 aces + 4 kings + 4 queens
        // This tests the logic paths for multiple high-count ranks
        assert_poker_hands(
            "AS AH AC AD KS KH KC KD QS QH QC QD", // 4A + 4K + 4Q
            &[
                HighCard,
                OnePair,
                TwoPair,
                ThreeOfAKind,
                FullHouse,
                FourOfAKind,
            ],
        );

        // Note: To truly test 6+ cards of same rank, we'd need to manually construct
        // rank_counts, but this tests that our logic handles multiple four-of-a-kinds correctly
    }

    fn assert_poker_hands(hand_str: &str, expected_hands: &[PokerHand]) {
        let hand = Card::make_hand(hand_str).unwrap();
        let mut hands_count = PokerHandsCount::new();
        PokerHandResolver::poker_hands(&hand, &mut hands_count);

        // Check that each element is at most 1
        for (i, &count) in hands_count.iter().enumerate() {
            assert!(
                count <= 1,
                "hands_count[{}] = {} (should be 0 or 1)",
                i,
                count
            );
        }

        // Convert to HashSet for comparison
        let mut actual_hands = HashSet::new();

        for poker_hand in PokerHand::iter() {
            if hands_count[poker_hand] > 0 {
                actual_hands.insert(poker_hand);
            }
        }

        let expected_set: HashSet<PokerHand> =
            expected_hands.iter().cloned().collect();
        assert_eq!(actual_hands, expected_set);
    }
}
