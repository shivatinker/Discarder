//
//  DeckView.swift
//  Discarder
//
//  Created by Andrii Zinoviev on 14.06.2025.
//

import DiscarderKit
import SwiftUI

struct DeckView: View {
    let deck: Deck
    
    let action: (UUID) -> Void
    let removeAction: (UUID) -> Void
    
    private func cards(for suit: Suit) -> [DeckCard] {
        self.deck.cards
            .filter { $0.card.suit == suit }
            .sorted(using: KeyPathComparator(\.card.rank))
    }
    
    var body: some View {
        GroupBox("Deck") {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Suit.allCases, id: \.self) { suit in
                    CardStack(spacing: 2, overlap: 20) {
                        ForEach(self.cards(for: suit)) { card in
                            CardView(
                                card: card.card,
                                isDiscarded: false,
                                action: {
                                    self.action(card.id)
                                },
                                removeAction: {
                                    self.removeAction(card.id)
                                }
                            )
                        }
                    }
                    .frame(height: 60)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

#Preview {
    DeckView(
        deck: .makeStandard(),
        action: { print("action \($0)") },
        removeAction: { print("remove \($0)") }
    )
    .padding()
}
