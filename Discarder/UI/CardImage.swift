//
//  CardImage.swift
//  Discarder
//
//  Created by Andrii Zinoviev on 14.06.2025.
//

import DiscarderKit
import SwiftUI

struct CardImage: View {
    enum Kind {
        case card(Card)
        case placeholder
    }
    
    let kind: Kind
    
    init(_ kind: Kind) {
        self.kind = kind
    }
    
    var body: some View {
        Image(self.imageName)
            .interpolation(.none)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 42, height: 60)
            .opacity(self.opacity)
    }
    
    private var opacity: Double {
        switch self.kind {
        case .placeholder:
            0.4
            
        case .card:
            1
        }
    }
    
    private var imageName: String {
        switch self.kind {
        case let .card(card):
            self.cardImageName(card)
            
        case .placeholder:
            "card_empty"
        }
    }
    
    private func cardImageName(_ card: Card) -> String {
        "card_\(self.imageSuitName(card.suit))_\(self.imageRankName(card.rank))"
    }
    
    private func imageSuitName(_ suit: Suit) -> String {
        switch suit {
        case .spades: "spades"
        case .hearts: "hearts"
        case .diamonds: "diamonds"
        case .clubs: "clubs"
        }
    }
    
    private func imageRankName(_ rank: Rank) -> String {
        if rank.index < 10 {
            "0\(rank.index)"
        }
        else if rank.index == 10 {
            "10"
        }
        else {
            rank.description
        }
    }
}
