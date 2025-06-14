use crate::{
    deck::{Card, Deck, Rank, Suit},
    discarder::Discarder,
};
use std::ptr;

#[repr(C)]
pub struct CRank {
    pub value: u8,
}

#[repr(C)]
pub struct CSuit {
    pub value: u8,
}

#[repr(C)]
pub struct CCard {
    pub rank: CRank,
    pub suit: CSuit,
}

#[repr(C)]
pub struct CPokerHandsCount {
    pub counts: [i64; 10],
}

pub type ProgressHandler = extern "C" fn(
    context: *mut std::ffi::c_void,
    counts: *const CPokerHandsCount,
    iterations: usize,
    fraction: f64,
);

#[no_mangle]
pub extern "C" fn discarder_new(
    deck: *const CCard,
    deck_size: usize,
    hand_size: usize,
    seed: u64,
) -> *mut Discarder {
    if deck_size > 0 && deck.is_null() {
        panic!("deck pointer must not be null when deck_size > 0");
    }

    let deck_cards = if deck_size > 0 {
        unsafe { std::slice::from_raw_parts(deck, deck_size) }
    } else {
        &[]
    };

    let rust_deck: Vec<Card> = deck_cards
        .iter()
        .map(|c| {
            Card::new(
                Rank {
                    value: c.rank.value,
                },
                Suit {
                    value: c.suit.value,
                },
            )
        })
        .collect();

    let discarder = Discarder::new(Deck::new(&rust_deck), hand_size, seed);
    Box::into_raw(Box::new(discarder))
}

#[no_mangle]
pub extern "C" fn discarder_free(discarder: *mut Discarder) {
    if !discarder.is_null() {
        unsafe {
            let _ = Box::from_raw(discarder);
        }
    }
}

#[no_mangle]
pub extern "C" fn discarder_run(
    discarder: *const Discarder,
    hand: *const CCard,
    hand_size: usize,
    max_iterations: usize,
    out_counts: *mut CPokerHandsCount,
    progress_handler: ProgressHandler,
    context: *mut std::ffi::c_void,
) -> usize {
    if discarder.is_null() {
        panic!("discarder pointer must not be null");
    }
    if hand_size > 0 && hand.is_null() {
        panic!("hand pointer must not be null when hand_size > 0");
    }
    if out_counts.is_null() {
        panic!("out_counts pointer must not be null");
    }

    let discarder = unsafe { &*discarder };
    let hand = if hand_size > 0 {
        unsafe { std::slice::from_raw_parts(hand, hand_size) }
    } else {
        &[]
    };

    let rust_hand: Vec<Card> = hand
        .iter()
        .map(|c| {
            Card::new(
                Rank {
                    value: c.rank.value,
                },
                Suit {
                    value: c.suit.value,
                },
            )
        })
        .collect();

    let result = discarder.run(&rust_hand, max_iterations, |progress| {
        let mut c_counts = CPokerHandsCount { counts: [0; 10] };
        progress.count.to_array(&mut c_counts.counts);
        progress_handler(
            context,
            &c_counts,
            progress.iterations,
            progress.fraction_completed,
        );
    });

    unsafe {
        result.count.to_array(&mut (*out_counts).counts);
    }

    result.iterations
}
