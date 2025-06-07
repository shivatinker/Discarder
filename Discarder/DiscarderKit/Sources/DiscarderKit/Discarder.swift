//
//  Discarder.swift
//  DiscarderKit
//
//  Created by Andrii Zinoviev on 07.06.2025.
//

import Algorithms
import Foundation

struct Deck {
    var cards = Multiset<Card>()
    
    static func makeStandard() -> Deck {
        var deck = Deck()
        
        for suit in Suit.allCases {
            for rank in Rank.allCases {
                deck.cards.insert(Card(rank: rank, suit: suit))
            }
        }
        
        return deck
    }
}

public struct DiscarderResult: Sendable, CustomStringConvertible {
    public var iterations: Int = 0
    public var outs: [PokerHandKind: Int] = [:]
    
    public var description: String {
        self.outs.sorted(by: { $0.value > $1.value }).map(self.row(for:)).joined(separator: "\n")
    }
    
    private func row(for out: (PokerHandKind, Int)) -> String {
        let percentage = self.iterations == 0 ? 0 : Double(out.1) / Double(self.iterations) * 100
        let percentageString = String(format: "%.2f%%", percentage)
        
        return "\(out.0): \(out.1) \(percentageString)"
    }
}

public struct DiscarderAlgorithm: MonteCarloAlgorithm {
    public typealias Output = DiscarderResult
    
    public static let initialOutput = DiscarderResult()
    
    private let resolver = PokerHandResolver()
    
    let deck: Deck
    let drawSize: Int
    let hand: Multiset<Card>
    
    public init(hand: Multiset<Card>, discards: Multiset<Card>) {
        self.drawSize = discards.count
        
        var deck = Deck.makeStandard()
        deck.cards.remove(hand)
        self.deck = deck
        
        var remainingHand = hand
        remainingHand.remove(discards)
        self.hand = remainingHand
    }
    
    public func performIteration(
        random: inout some RandomNumberGenerator,
        output: inout DiscarderResult,
        iterations: Int
    ) {
        let draw = self.deck.cards.allElements.randomSample(
            count: self.drawSize,
            using: &random
        )
        
        var drawnHand = self.hand
        drawnHand.insert(draw)
        
        let handArray = Array(drawnHand.allElements)
        
        for hand in self.resolver.pokerHands(in: handArray) {
            output.outs[hand, default: 0] += 1
        }
        
        output.iterations = iterations
    }
}
