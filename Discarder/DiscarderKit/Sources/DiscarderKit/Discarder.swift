//
//  Discarder.swift
//  DiscarderKit
//
//  Created by Andrii Zinoviev on 07.06.2025.
//

import Algorithms
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
}

public struct DiscarderAlgorithm: MonteCarloAlgorithm, Sendable {
    public typealias Output = DiscarderResult
    
    public static let initialOutput = DiscarderResult()
    
    private let resolver = PokerHandResolver()
    
    let deck: Deck
    let drawCount: Int
    let hand: [Card]
    
    public init(hand: [Card], deck: Deck, drawCount: Int) {
        self.hand = hand
        self.deck = deck
        self.drawCount = drawCount
    }
    
    public func performIteration(
        random: inout some RandomNumberGenerator,
        output: inout DiscarderResult,
        iterations: Int
    ) {
        let draw = self.deck.cards.randomSample(
            count: self.drawCount,
            using: &random
        )
        
        var drawnHand = self.hand
        drawnHand.append(contentsOf: draw)
        
        for hand in self.resolver.pokerHands(in: drawnHand) {
            output.outs[hand, default: 0] += 1
        }
        
        output.iterations = iterations
    }
}
