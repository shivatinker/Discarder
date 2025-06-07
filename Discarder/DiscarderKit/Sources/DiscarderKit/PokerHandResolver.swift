//
//  PokerHandResolver.swift
//  DiscarderKit
//
//  Created by Andrii Zinoviev on 07.06.2025.
//

import Algorithms

public enum PokerHandKind: Comparable, CaseIterable, Sendable {
    case highCard
    case onePair
    case twoPair
    case threeOfAKind
    case straight
    case flush
    case fullHouse
    case fourOfAKind
    case straightFlush
    case royalFlush
    
    fileprivate var resolverType: any PokerHandResolving.Type {
        switch self {
        case .highCard: HighCardResolver.self
        case .onePair: OnePairResolver.self
        case .twoPair: TwoPairResolver.self
        case .threeOfAKind: ThreeOfAKindResolver.self
        case .straight: StraightResolver.self
        case .flush: FlushResolver.self
        case .fullHouse: FullHouseResolver.self
        case .fourOfAKind: FourOfAKindResolver.self
        case .straightFlush: StraightFlushResolver.self
        case .royalFlush: RoyalFlushResolver.self
        }
    }
}

extension PokerHandKind: CustomStringConvertible {
    public var description: String {
        switch self {
        case .highCard: return "High Card"
        case .onePair: return "One Pair"
        case .twoPair: return "Two Pair"
        case .threeOfAKind: return "Three of a Kind"
        case .straight: return "Straight"
        case .flush: return "Flush"
        case .fullHouse: return "Full House"
        case .fourOfAKind: return "Four of a Kind"
        case .straightFlush: return "Straight Flush"
        case .royalFlush: return "Royal Flush"
        }
    }
}

protocol PokerHandResolving {
    init()
    var count: Int { get }
    func isPokerHand(_ hand: [Card]) -> Bool
}

struct PokerHandResolver {
    func pokerHands(in hand: [Card]) -> Set<PokerHandKind> {
        if hand.isEmpty {
            return []
        }
        
        var result: Set<PokerHandKind> = []
        
        for kind in PokerHandKind.allCases {
            let resolverType = kind.resolverType
            let resolver = resolverType.init()
            let handCount = resolver.count
            
            for subset in hand.combinations(ofCount: handCount) {
                if resolver.isPokerHand(subset) {
                    result.insert(kind)
                }
            }
        }
        
        return result
    }
}

private struct HighCardResolver: PokerHandResolving {
    let count = 1
    
    func isPokerHand(_ hand: [Card]) -> Bool {
        precondition(hand.count == self.count)
        return true
    }
}

private struct OnePairResolver: PokerHandResolving {
    let count = 2
    
    func isPokerHand(_ hand: [Card]) -> Bool {
        precondition(hand.count == self.count)
        return hand.allHasSame(\.rank)
    }
}

private struct TwoPairResolver: PokerHandResolving {
    let count = 4
    
    func isPokerHand(_ hand: [Card]) -> Bool {
        precondition(hand.count == self.count)
        
        let sortedRanks = hand.map(\.rank).sorted()
        
        // Two pair pattern: AABB or AAAA (four of a kind contains two pair)
        return sortedRanks[0] == sortedRanks[1] &&
            sortedRanks[2] == sortedRanks[3]
    }
}

private struct ThreeOfAKindResolver: PokerHandResolving {
    let count = 3
    
    func isPokerHand(_ hand: [Card]) -> Bool {
        precondition(hand.count == self.count)
        return hand.allHasSame(\.rank)
    }
}

private struct StraightResolver: PokerHandResolving {
    let count = 5
    
    func isPokerHand(_ hand: [Card]) -> Bool {
        precondition(hand.count == self.count)
        
        let sortedRanks = hand.map(\.rank).sorted()
        
        if sortedRanks == [2, 3, 4, 5, .ace] {
            return true
        }
        
        // Check for consecutive ranks
        for i in 1..<sortedRanks.count {
            if sortedRanks[i].index != sortedRanks[i - 1].index + 1 {
                return false
            }
        }
        
        return true
    }
}

private struct FlushResolver: PokerHandResolving {
    let count = 5
    
    func isPokerHand(_ hand: [Card]) -> Bool {
        precondition(hand.count == self.count)
        return hand.allHasSame(\.suit)
    }
}

private struct FullHouseResolver: PokerHandResolving {
    let count = 5
    
    func isPokerHand(_ hand: [Card]) -> Bool {
        precondition(hand.count == self.count)
        
        let sortedRanks = hand.map(\.rank).sorted()
        
        // Full house patterns: AAABB or AABBB
        return (sortedRanks[0] == sortedRanks[1] && sortedRanks[1] == sortedRanks[2] && sortedRanks[3] == sortedRanks[4]) ||
            (sortedRanks[0] == sortedRanks[1] && sortedRanks[2] == sortedRanks[3] && sortedRanks[3] == sortedRanks[4])
    }
}

private struct FourOfAKindResolver: PokerHandResolving {
    let count = 4
    
    func isPokerHand(_ hand: [Card]) -> Bool {
        precondition(hand.count == self.count)
        return hand.allHasSame(\.rank)
    }
}

private struct StraightFlushResolver: PokerHandResolving {
    let count = 5
    
    func isPokerHand(_ hand: [Card]) -> Bool {
        precondition(hand.count == self.count)
        
        // Must be both a straight and a flush
        let straightResolver = StraightResolver()
        let flushResolver = FlushResolver()
        
        return straightResolver.isPokerHand(hand) && flushResolver.isPokerHand(hand)
    }
}

private struct RoyalFlushResolver: PokerHandResolving {
    let count = 5
    
    func isPokerHand(_ hand: [Card]) -> Bool {
        precondition(hand.count == self.count)
        
        // Must be a straight flush to A
        guard StraightFlushResolver().isPokerHand(hand) else {
            return false
        }
        
        return Set(hand.map(\.rank)) == [.ace, .king, .queen, .jack, 10]
    }
}

extension Sequence {
    func allHasSame<T: Equatable>(_ value: (Element) -> T) -> Bool {
        var sameValue: T?
        
        for element in self {
            let currentValue = value(element)
            
            if let sameValue {
                if sameValue != currentValue {
                    return false
                }
            }
            else {
                sameValue = currentValue
            }
        }
        
        return true
    }
}
