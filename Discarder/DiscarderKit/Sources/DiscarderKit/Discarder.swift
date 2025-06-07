//
//  Discarder.swift
//  DiscarderKit
//
//  Created by Andrii Zinoviev on 07.06.2025.
//

import Foundation

public struct Deck: ExpressibleByArrayLiteral, Sendable {
    public var cards: [Card] = []
    
    public init(_ cards: [Card]) {
        self.cards = cards
    }
    
    public init(arrayLiteral elements: Card...) {
        self.init(elements)
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

public struct DiscarderResult: Sendable, CustomStringConvertible {
    public var iterations: Int = 0
    public var outs: [PokerHandKind: Int] = [:]
    
    public init() {}
    
    public var description: String {
        """
        Iteration \(self.iterations)
        \(self.outs.sorted(by: { $0.value > $1.value }).map(self.row(for:)).joined(separator: "\n"))
        """
    }
    
    private func row(for out: (PokerHandKind, Int)) -> String {
        let percentage = self.iterations == 0 ? 0 : Double(out.1) / Double(self.iterations) * 100
        let percentageString = String(format: "%.2f%%", percentage)
        
        return "\(out.0): \(out.1) \(percentageString)"
    }
    
    public static var test: Self {
        var result = DiscarderResult()
        
        result.iterations = 10_000
        result.outs[.royalFlush] = 3
        result.outs[.straightFlush] = 10
        result.outs[.fourOfAKind] = 100
        result.outs[.fullHouse] = 422
        result.outs[.flush] = 3423
        result.outs[.straight] = 5432
        
        return result
    }
}

public struct DiscarderAlgorithm: MonteCarloAlgorithm, Sendable {
    public typealias Output = DiscarderResult
    
    public static let initialOutput = DiscarderResult()
    
    let deck: Deck
    let drawCount: Int
    let hand: [Card]
    
    public init(hand: [Card], deck: Deck, drawCount: Int) {
        self.hand = hand
        self.deck = deck
        self.drawCount = drawCount
    }
    
    public final class Context {
        let resolver = PokerHandResolver()
        var hand: [Card] = []
        var indices: [Int] = []
        
        init(capacity: Int, deckSize: Int) {
            self.hand.reserveCapacity(capacity)
            self.indices = Array(0..<deckSize)
        }
    }
    
    public func makeContext() -> Context {
        Context(capacity: self.hand.count + self.drawCount, deckSize: self.deck.cards.count)
    }
    
    public func performIteration(
        context: Context,
        random: inout some RandomNumberGenerator,
        output: inout DiscarderResult
    ) {
        // Pre-allocate a fixed-size array to avoid repeated allocations
        context.hand.removeAll(keepingCapacity: true)
        context.hand.append(contentsOf: self.hand)
        
        // Sample directly into the drawnHand array to avoid intermediate allocations
        self.sampleInto(
            &context.hand,
            from: self.deck.cards,
            count: self.drawCount,
            using: &random,
            indices: &context.indices
        )
        
        // Use optimized hand detection that updates output directly
        context.resolver.updateOuts(for: context.hand, output: &output)
        
        output.iterations += 1
    }
    
    private func sampleInto<T>(
        _ target: inout [T],
        from array: [T],
        count k: Int,
        using random: inout some RandomNumberGenerator,
        indices: inout [Int]
    ) {
        let n = array.count
        guard k > 0, k <= n else { return }
        
        // Use Fisher-Yates for all cases - simpler and still very fast
        self.sampleUsingFisherYates(&target, from: array, count: k, using: &random, indices: &indices)
    }
    
    private func sampleUsingFisherYates<T>(
        _ target: inout [T],
        from array: [T],
        count k: Int,
        using random: inout some RandomNumberGenerator,
        indices: inout [Int]
    ) {
        let n = array.count
        
        // Reset indices to sequential order (reuse the pre-allocated array)
        for i in 0..<n {
            indices[i] = i
        }
        
        for i in 0..<k {
            let j = Int.random(in: i..<n, using: &random)
            indices.swapAt(i, j)
            target.append(array[indices[i]])
        }
    }
    
    public func combine(output: DiscarderResult, into other: inout DiscarderResult) {
        other.iterations += output.iterations
        
        for (hand, count) in output.outs {
            other.outs[hand, default: 0] += count
        }
    }
}
