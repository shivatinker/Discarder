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
    let hand: [HandCard]
    let maxCount: Int
    let action: (Card) -> Void
    let removeAction: (Card) -> Void
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(
                self.hand.sorted(using: KeyPathComparator(\.card.rank, order: .reverse)),
                id: \.card
            ) { card in
                VStack(spacing: 2) {
                    CardView(card: card.card)
                        .overlay {
                            if card.isDiscarded {
                                Rectangle()
                                    .fill(.red.opacity(0.3))
                            }
                        }
                        .onTapGesture {
                            self.action(card.card)
                        }
                    
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                        .onTapGesture {
                            self.removeAction(card.card)
                        }
                }
            }
            
            ForEach(0..<(self.maxCount - self.hand.count), id: \.self) { index in
                CardImage(.placeholder)
            }
        }
    }
}

struct HandCard {
    var card: Card
    var isDiscarded: Bool
}

@MainActor
final class MainViewModel: ObservableObject, MCSimulatorDelegate {
    @Published
    private(set) var result = DiscarderResult()
    
    @Published
    private(set) var deck = Deck.makeStandard()
    
    @Published
    private(set) var hand: [HandCard] = []
    
    @Published
    private(set) var handSize = 8
    
    @Published
    private(set) var isLoading = false
    
    private var task: Task<Void, Never>?
    
    private func startIterating() {
        let oldTask = self.task
        oldTask?.cancel()
        
        self.task = Task {
            do {
                await oldTask?.value
                
                self.isLoading = true
                defer { self.isLoading = false }
                
                let remainingHand = self.hand.filter { false == $0.isDiscarded }.map(\.card)
                
                let simulator = MCSimulator(
                    seed: 42,
                    algorithm: DiscarderAlgorithm(
                        hand: remainingHand,
                        deck: self.deck,
                        drawCount: self.handSize - remainingHand.count
                    )
                )
                
                simulator.setDelegate(self)
                
                try await simulator.run(iterations: 1_000_000)
            }
            catch {
                if false == error is CancellationError {
                    print(error)
                }
            }
        }
    }
    
    func handleDeckAction(_ card: Card) {
        if self.hand.count < self.handSize {
            self.hand.append(HandCard(card: card, isDiscarded: false))
            self.deck.cards.removeAll { $0 == card }
            self.startIterating()
        }
    }
    
    func handleHandAction(_ card: Card) {
        for (index, handCard) in self.hand.enumerated() {
            if handCard.card == card {
                self.hand[index].isDiscarded.toggle()
            }
        }
        
        self.startIterating()
    }
    
    func handleHandRemoveAction(_ card: Card) {
        for (index, handCard) in self.hand.enumerated() {
            if handCard.card == card {
                self.hand.remove(at: index)
                self.deck.cards.append(card)
            }
        }
        
        self.startIterating()
    }
    
    nonisolated func handleUpdate(_ output: DiscarderResult) {
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
                    maxCount: self.model.handSize,
                    action: self.model.handleHandAction,
                    removeAction: self.model.handleHandRemoveAction
                )
            }
            .fixedSize(horizontal: false, vertical: true)
            
            Divider()
            
            ResultView(isLoading: self.model.isLoading, result: self.model.result)
                .frame(width: 400)
        }
        .padding()
    }
}

struct ResultView: View {
    let isLoading: Bool
    let result: DiscarderResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Iteration #\(self.result.iterations)")
                .font(.title2)
                .monospacedDigit()
            
            if self.result.iterations == 0 {
                Text("No iterations yet")
                    .foregroundStyle(.secondary)
            }
            else {
                ForEach(self.result.outs.sorted(by: { $0.value > $1.value }), id: \.key) { hand, outs in
                    ResultCard(
                        hand: hand,
                        outs: outs,
                        percentage: Double(outs) / Double(self.result.iterations) * 100
                    )
                }
            }
        }
        .overlay {
            if self.isLoading {
                ProgressView()
                    .scaleEffect(0.5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .frame(maxHeight: .infinity, alignment: .topLeading)
    }
}

struct ResultCard: View {
    let hand: PokerHandKind
    let outs: Int
    let percentage: Double
    
    var body: some View {
        HStack(alignment: .center) {
            Text(self.hand.description)
                .font(.headline)
            
            Spacer()
            
            HStack(spacing: 8) {
                Text("\(String(format: "%.3f", self.percentage))%")
                    .font(.title3)
                    .foregroundStyle(.cyan)
                    .bold()
                    .monospacedDigit()
                    .frame(width: 100, alignment: .trailing)
                
                Text("\(self.outs)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                    .frame(width: 100, alignment: .leading)
                    .fixedSize(horizontal: true, vertical: false)
            }
        }
    }
}

#Preview {
    ContentView(
        model: MainViewModel()
    )
    .frame(height: 400)
}

#Preview {
    ResultView(isLoading: true, result: .test)
        .frame(width: 300)
}
