//
//  PokerHandResolver.swift
//  DiscarderKit
//
//  Created by Andrii Zinoviev on 07.06.2025.
//

public final class PokerHandResolver {
    private let ranks = Rank.allCases
    private let suits = Suit.allCases
    private let offset: Int
    private let rankCount: Int
    private let suitCount: Int
    
    // Pre-allocated arrays for reuse
    private var rankCounts: [Int]
    private var suitCounts: [Int]
    private var suitMasks: [UInt16]
    
    // Pre-computed straights
    private let straights: [UInt16]
    private let wheel: UInt16
    private let royal: UInt16
    
    init() {
        self.offset = self.ranks.first!.index
        self.rankCount = self.ranks.count
        self.suitCount = self.suits.count
        
        // Pre-allocate arrays
        self.rankCounts = [Int](repeating: 0, count: self.rankCount)
        self.suitCounts = [Int](repeating: 0, count: self.suitCount)
        self.suitMasks = [UInt16](repeating: 0, count: self.suitCount)
        
        // Pre-compute straights
        let straightBits: UInt16 = 0b11111
        var tempStraights = [UInt16]()
        tempStraights.reserveCapacity(self.rankCount - 4)
        
        for i in 0...self.rankCount - 5 {
            tempStraights.append(straightBits << UInt16(i))
        }
        
        self.wheel = (1 << UInt16(self.rankCount - 1)) | (straightBits >> 1)
        tempStraights.append(self.wheel)
        self.straights = tempStraights
        
        self.royal = straightBits << UInt16(self.rankCount - 5)
    }
    
    // Optimized method that updates output directly without Set allocation
    func updateOuts(for hand: [Card], output: inout DiscarderResult) {
        // Reset arrays for reuse
        for i in 0..<self.rankCount {
            self.rankCounts[i] = 0
        }
        for i in 0..<self.suitCount {
            self.suitCounts[i] = 0
            self.suitMasks[i] = 0
        }
        
        var mask: UInt16 = 0
        
        // Count cards
        for c in hand {
            let r = Int(c.rank.index - self.offset)
            let s = self.suits.firstIndex(of: c.suit)!
            self.rankCounts[r] += 1
            self.suitCounts[s] += 1
            let bit: UInt16 = 1 << UInt16(r)
            self.suitMasks[s] |= bit
            mask |= bit
        }
        
        if hand.isEmpty { return }
        
        // Always count high card
        output.outs[.highCard, default: 0] += 1
        
        // Check for straight flush and royal flush
        var hasStraightFlush = false
        var hasRoyalFlush = false
        for i in 0..<self.suitCount where self.suitCounts[i] >= 5 {
            let sm = self.suitMasks[i]
            for straight in self.straights {
                if sm & straight == straight {
                    hasStraightFlush = true
                    if sm & self.royal == self.royal {
                        hasRoyalFlush = true
                    }
                    break
                }
            }
            if hasStraightFlush { break }
        }
        
        // Count pairs, trips, and four of a kinds
        var pairs = 0
        var trips = 0
        var fourOfAKinds = 0
        
        for count in self.rankCounts {
            if count >= 4 {
                fourOfAKinds += 1
                trips += 1
                pairs += 1
            }
            else if count >= 3 {
                trips += 1
                pairs += 1
            }
            else if count >= 2 {
                pairs += 1
            }
        }
        
        // Check for flush
        var hasFlush = false
        for count in self.suitCounts {
            if count >= 5 {
                hasFlush = true
                break
            }
        }
        
        // Check for straight
        var hasStraight = false
        for straight in self.straights {
            if mask & straight == straight {
                hasStraight = true
                break
            }
        }
        
        // Update output directly based on detected hands
        if hasRoyalFlush {
            output.outs[.royalFlush, default: 0] += 1
        }
        if hasStraightFlush {
            output.outs[.straightFlush, default: 0] += 1
        }
        if fourOfAKinds >= 1 {
            output.outs[.fourOfAKind, default: 0] += 1
            output.outs[.twoPair, default: 0] += 1
        }
        if (trips >= 1 && pairs >= 2) || trips >= 2 {
            output.outs[.fullHouse, default: 0] += 1
        }
        if hasFlush {
            output.outs[.flush, default: 0] += 1
        }
        if hasStraight {
            output.outs[.straight, default: 0] += 1
        }
        if trips >= 1 {
            output.outs[.threeOfAKind, default: 0] += 1
        }
        if pairs >= 2 {
            output.outs[.twoPair, default: 0] += 1
        }
        if pairs >= 1 {
            output.outs[.onePair, default: 0] += 1
        }
    }
}
