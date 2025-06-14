//
//  Deck.swift
//  DiscarderKit
//
//  Created by Andrii Zinoviev on 07.06.2025.
//

import Foundation
import IdentifiedCollections

public struct DeckCard: Identifiable, Sendable {
    public var id: UUID
    public var card: Card
    
    public init(id: UUID, card: Card) {
        self.id = id
        self.card = card
    }
}

public struct Deck: Sendable {
    public var cards: IdentifiedArrayOf<DeckCard> = []
    
    public init() {}
    
    var isEmpty: Bool {
        self.cards.isEmpty
    }
    
    var count: Int {
        self.cards.count
    }
    
    public static func makeStandard() -> Deck {
        var deck = Deck()
        
        for suit in Suit.allCases {
            for rank in Rank.allCases {
                deck.cards.append(
                    DeckCard(
                        id: UUID(),
                        card: Card(rank: rank, suit: suit)
                    )
                )
            }
        }
        
        return deck
    }
}
