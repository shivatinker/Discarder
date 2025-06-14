//
//  AllCardsView.swift
//  Discarder
//
//  Created by Andrii Zinoviev on 14.06.2025.
//

import DiscarderKit
import SwiftUI

struct AllCardsView: View {
    let action: (Card) -> Void
    
    var body: some View {
        GroupBox("All Cards") {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Suit.allCases, id: \.self) { suit in
                    CardStack(spacing: 2, overlap: 20) {
                        ForEach(self.cards(for: suit), id: \.self) { card in
                            CardView(
                                card: card,
                                isDiscarded: false,
                                action: {
                                    self.action(card)
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
    
    private func cards(for suit: Suit) -> [Card] {
        Card.allCards
            .filter { $0.suit == suit }
            .sorted(using: KeyPathComparator(\.rank))
    }
}

#Preview {
    AllCardsView { _ in }
        .padding()
}
