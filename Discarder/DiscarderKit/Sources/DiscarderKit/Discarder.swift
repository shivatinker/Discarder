//
//  Discarder.swift
//  DiscarderKit
//
//  Created by Andrii Zinoviev on 13.06.2025.
//

internal import RustCore
import Foundation

public final class Discarder {
    private let queue = DispatchQueue(label: "com.shivatinker.discarder.worker", qos: .default)
    private let instance: OpaquePointer
    
    public init(deck: Deck, handSize: Int, seed: UInt64) {
        let cCards = deck.makeCCardArray()
        
        self.instance = cCards.withUnsafeBufferPointer { ptr in
            discarder_new(
                ptr.baseAddress!,
                UInt(cCards.count),
                UInt(handSize),
                seed
            )
        }
    }
    
    public func run(
        hand: [Card],
        maxIterations: Int,
        resultHandler: @Sendable @escaping (DiscarderResult) -> Void
    ) async {
        nonisolated(unsafe) let instance = self.instance
        
        let wrapper = ProgressWrapper(handler: resultHandler)
        
        // TODO: Cancellation
        await withCheckedContinuation { continuation in
            self.queue.async {
                var counts = CPokerHandsCount()
                let cCards = hand.map { $0.makeCCard() }
                
                let iterations = cCards.withUnsafeBufferPointer { ptr in
                    discarder_run(
                        instance,
                        ptr.baseAddress!,
                        UInt(cCards.count),
                        UInt(maxIterations),
                        &counts,
                        { ctx, counts, iterations, fraction in
                            let wrapper = Unmanaged<ProgressWrapper>.fromOpaque(ctx!).takeUnretainedValue()
                            
                            let result = DiscarderResult(
                                iterations: iterations,
                                count: counts!.pointee
                            )
                            
                            wrapper.handler(result)
                        },
                        Unmanaged.passUnretained(wrapper).toOpaque()
                    )
                }
                
                print(iterations)
                
                resultHandler(
                    DiscarderResult(
                        iterations: iterations,
                        count: counts
                    )
                )
                
                continuation.resume()
            }
        }
    }
    
    deinit {
        discarder_free(self.instance)
    }
}

private final class ProgressWrapper: Sendable {
    let handler: @Sendable (DiscarderResult) -> Void
    
    init(handler: @Sendable @escaping (DiscarderResult) -> Void) {
        self.handler = handler
    }
}

extension DiscarderResult {
    init(iterations: UInt, count: CPokerHandsCount) {
        let outs = PokerHandKind.allCases.map {
            switch $0 {
            case .highCard: ($0, count.counts.0)
            case .onePair: ($0, count.counts.1)
            case .twoPair: ($0, count.counts.2)
            case .threeOfAKind: ($0, count.counts.3)
            case .straight: ($0, count.counts.4)
            case .flush: ($0, count.counts.5)
            case .fullHouse: ($0, count.counts.6)
            case .fourOfAKind: ($0, count.counts.7)
            case .straightFlush: ($0, count.counts.8)
            case .royalFlush: ($0, count.counts.9)
            }
        }
        
        self.init(
            iterations: Int64(iterations),
            outs: .init(uniqueKeysWithValues: outs)
        )
    }
}

extension Card {
    fileprivate func makeCCard() -> CCard {
        CCard(
            rank: CRank(value: UInt8(self.rank.index)),
            suit: CSuit(value: UInt8(self.suit.rawValue))
        )
    }
}

extension Deck {
    fileprivate func makeCCardArray() -> [CCard] {
        self.cards.map { $0.makeCCard() }
    }
}
