//
//  ContentView.swift
//  Discarder
//
//  Created by Andrii Zinoviev on 07.06.2025.
//

import DiscarderKit
import SwiftUI

private struct CardImage: View {
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
            .frame(width: 42)
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

struct CardView: View {
    @State
    private var isHovered: Bool = false
    
    let card: Card
    
    var body: some View {
        CardImage(.card(self.card))
            .overlay {
                if self.isHovered {
                    Rectangle()
                        .fill(Color.blue.opacity(0.1))
                }
            }
            .onHover { self.isHovered = $0 }
    }
}

struct DeckView: View {
    let deck: Deck
    let action: (Card) -> Void
    
    var body: some View {
        LazyVGrid(
            columns: Array(
                repeating: GridItem(
                    .fixed(42),
                    spacing: 2
                ),
                count: 13
            ),
            spacing: 2
        ) {
            ForEach(self.deck.cards.sorted(), id: \.self) { card in
                CardView(card: card)
                    .onTapGesture {
                        self.action(card)
                    }
            }
        }
    }
}

struct HandView: View {
    let hand: [Card]
    let maxCount: Int
    let action: (Card) -> Void
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(self.hand.sorted(), id: \.self) { card in
                CardView(card: card)
                    .onTapGesture {
                        self.action(card)
                    }
            }
            
            ForEach(0..<(self.maxCount - self.hand.count), id: \.self) { index in
                CardImage(.placeholder)
            }
        }
    }
}

@MainActor
final class MainViewModel: ObservableObject, MCSimulatorDelegate {
    @Published
    private(set) var result = DiscarderResult()
    
    @Published
    private(set) var deck = Deck.makeStandard()
    
    @Published
    private(set) var hand: [Card] = []
    
    @Published
    private(set) var handSize = 8
    
    private var task: Task<Void, Never>?
    
    private func startIterating() {
        let oldTask = self.task
        oldTask?.cancel()
        
        self.task = Task {
            do {
                await oldTask?.value
                
                let simulator = MCSimulator(
                    seed: 42,
                    algorithm: DiscarderAlgorithm(
                        hand: self.hand,
                        deck: self.deck,
                        drawCount: self.handSize - self.hand.count
                    )
                )
                
                await simulator.setDelegate(self)
                
                try await simulator.iterate(count: 1000000)
            }
            catch {
                if false == error is CancellationError {
                    print(error)
                }
            }
        }
    }
    
    func handleDeckAction(_ card: Card) {
        if self.hand.count < 8 {
            self.hand.append(card)
            self.deck.cards.removeAll { $0 == card }
            self.startIterating()
        }
    }
    
    func handleHandAction(_ card: Card) {
        self.hand.removeAll { $0 == card }
        self.deck.cards.append(card)
        self.startIterating()
    }
    
    nonisolated func handleUpdate(_ output: DiscarderResult, iteration: Int) {
        Task { @MainActor in
            self.result = output
        }
    }
}

struct ContentView: View {
    @ObservedObject
    var model: MainViewModel
    
    var body: some View {
        HStack {
            VStack {
                DeckView(deck: self.model.deck) { card in
                    self.model.handleDeckAction(card)
                }
                
                HandView(
                    hand: self.model.hand,
                    maxCount: self.model.handSize
                ) { card in
                    self.model.handleHandAction(card)
                }
            }
            .fixedSize(horizontal: false, vertical: true)
            
            Divider()
            
            Text(self.model.result.description)
                .frame(width: 300, alignment: .topLeading)
                .frame(maxHeight: .infinity, alignment: .topLeading)
        }
        .padding()
    }
}

#Preview {
    ContentView(
        model: MainViewModel()
    )
    .frame(height: 400)
}
