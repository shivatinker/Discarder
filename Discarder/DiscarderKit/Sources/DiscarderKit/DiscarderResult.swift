//
//  DiscarderResult.swift
//  DiscarderKit
//
//  Created by Andrii Zinoviev on 13.06.2025.
//

import Foundation

public struct DiscarderResult: Sendable {
    public private(set) var iterations: Int64
    private var outs: [PokerHandKind: Int64]
    
    public init() {
        self.init(iterations: 0, outs: [:])
    }
    
    init(iterations: Int64, outs: [PokerHandKind: Int64]) {
        self.iterations = iterations
        self.outs = outs
    }
    
    private func outs(for kind: PokerHandKind) -> Int64 {
        self.outs[kind] ?? 0
    }
    
    public var allOuts: [(PokerHandKind, Int64)] {
        PokerHandKind.allCases.map {
            ($0, self.outs(for: $0))
        }
    }
    
    private func row(for out: (PokerHandKind, Int64)) -> String {
        let percentage = self.iterations == 0 ? 0 : Double(out.1) / Double(self.iterations) * 100
        let percentageString = String(format: "%.2f%%", percentage)
        
        return "\(out.0): \(out.1) \(percentageString)"
    }
    
#if DEBUG
    public static let test = DiscarderResult(
        iterations: 10_000,
        outs: [
            .royalFlush: 1,
            .straightFlush: 12,
            .fourOfAKind: 234,
            .fullHouse: 543,
            .flush: 1244,
            .straight: 1234,
            .threeOfAKind: 5321,
            .twoPair: 5433,
            .onePair: 8888,
            .highCard: 10_000,
        ]
    )
#endif
}

extension DiscarderResult: CustomStringConvertible {
    public var description: String {
        """
        Iteration \(self.iterations)
        \(self.allOuts.map(self.row(for:)).joined(separator: "\n"))
        """
    }
}
