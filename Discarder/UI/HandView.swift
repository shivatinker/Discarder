//
//  HandView.swift
//  Discarder
//
//  Created by Andrii Zinoviev on 14.06.2025.
//

import DiscarderKit
import IdentifiedCollections
import SwiftUI

enum HandCardID: Hashable {
    case card(UUID)
    case placeholder(Int)
}

enum HandCard: Identifiable {
    case card(DeckCard)
    case placeholder(Int)
    
    var id: HandCardID {
        switch self {
        case let .card(card):
            return .card(card.id)
        case let .placeholder(index):
            return .placeholder(index)
        }
    }
}
    
struct HandView: View {
    let maxSize: Int
    let cards: IdentifiedArrayOf<DeckCard>
    let discardedCards: Set<UUID>
    
    let discardHandler: (UUID) -> Void
    let removeHandler: (UUID) -> Void
    
    var body: some View {
        GroupBox("Hand") {
            HStack(spacing: 2) {
                ForEach(self.handCards) { card in
                    switch card {
                    case let .card(deckCard):
                        CardView(
                            card: deckCard.card,
                            isDiscarded: self.discardedCards.contains(deckCard.id),
                            action: {
                                self.discardHandler(deckCard.id)
                            },
                            removeAction: {
                                self.removeHandler(deckCard.id)
                            }
                        )
                        
                    case .placeholder:
                        CardImage(.placeholder)
                    }
                }
            }
        }
    }
    
    private var handCards: [HandCard] {
        (0..<self.maxSize).map { index in
            if index < self.cards.count {
                return .card(self.cards[index])
            }
            else {
                return .placeholder(index)
            }
        }
    }
}

#Preview {
    let id = UUID()
    
    HandView(
        maxSize: 8,
        cards: [
            DeckCard(id: UUID(), card: "5H"),
            DeckCard(id: UUID(), card: "TS"),
            DeckCard(id: id, card: "AD"),
            DeckCard(id: UUID(), card: "7C"),
            DeckCard(id: UUID(), card: "TH"),
        ],
        discardedCards: [id],
        discardHandler: { print("discard \($0)") },
        removeHandler: { print("remove \($0)") }
    )
    .padding()
}
