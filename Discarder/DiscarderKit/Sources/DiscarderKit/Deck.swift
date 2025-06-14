//
//  Deck.swift
//  DiscarderKit
//
//  Created by Andrii Zinoviev on 07.06.2025.
//

import Foundation

public struct Deck: Sendable {
    public var cards: [Card] = []
    
    public init(_ cards: [Card]) {
        self.cards = cards
    }
    
    var isEmpty: Bool {
        self.cards.isEmpty
    }
    
    var count: Int {
        self.cards.count
    }
    
    public static func makeStandard(without cards: Set<Card> = []) -> Deck {
        var deck = Deck()
        
        for suit in Suit.allCases {
            for rank in Rank.allCases {
                let card = Card(rank: rank, suit: suit)
                
                if false == cards.contains(card) {
                    deck.cards.append(card)
                }
            }
        }
        
        return deck
    }
}

extension Deck: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: Card...) {
        self.init(elements)
    }
}
