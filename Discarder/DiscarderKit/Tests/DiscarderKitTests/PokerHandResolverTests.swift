//
//  PokerHandResolverTests.swift
//  DiscarderKit
//
//  Created by Andrii Zinoviev on 07.06.2025.
//

@testable import DiscarderKit
import XCTest

final class PokerHandResolverTests: XCTestCase {
    // MARK: - Basic Hand Types
    
    func testHighCard() {
        self.test("2S", [.highCard])
        self.test("AH", [.highCard])
        self.test("2S 5H 7C 9D JH", [.highCard])
    }
    
    func testOnePair() {
        self.test("2S 2H", [.highCard, .onePair])
        self.test("AS AH", [.highCard, .onePair])
        self.test("KS KH 3C", [.highCard, .onePair])
    }
    
    func testTwoPair() {
        self.test("2S 2H 3C 3D", [.highCard, .onePair, .twoPair])
        self.test("AS AH KC KD", [.highCard, .onePair, .twoPair])
        self.test("7S 7H QC QD 5H", [.highCard, .onePair, .twoPair])
    }
    
    func testThreeOfAKind() {
        self.test("2S 2H 2C", [.highCard, .onePair, .threeOfAKind])
        self.test("AS AH AC", [.highCard, .onePair, .threeOfAKind])
        self.test("KS KH KC 5D 7H", [.highCard, .onePair, .threeOfAKind])
    }
    
    func testStraight() {
        self.test("2S 3H 4C 5D 6H", [.highCard, .straight])
        self.test("10S JH QC KD AH", [.highCard, .straight])
        self.test("AS 2H 3C 4D 5H", [.highCard, .straight]) // Ace-low straight
    }
    
    func testFlush() {
        self.test("2S 5S 7S 9S JS", [.highCard, .flush])
        self.test("AH 3H 6H 9H QH", [.highCard, .flush])
    }
    
    func testFullHouse() {
        self.test("2S 2H 2C 3D 3H", [.highCard, .onePair, .twoPair, .threeOfAKind, .fullHouse])
        self.test("AS AH AC KD KH", [.highCard, .onePair, .twoPair, .threeOfAKind, .fullHouse])
    }
    
    func testFourOfAKind() {
        self.test("2S 2H 2C 2D", [.highCard, .onePair, .threeOfAKind, .twoPair, .fourOfAKind])
        self.test("AS AH AC AD", [.highCard, .onePair, .threeOfAKind, .twoPair, .fourOfAKind])
        self.test("KS KH KC KD 5H", [.highCard, .onePair, .threeOfAKind, .twoPair, .fourOfAKind])
    }
    
    func testStraightFlush() {
        self.test("2S 3S 4S 5S 6S", [.highCard, .flush, .straight, .straightFlush])
        self.test("7H 8H 9H 10H JH", [.highCard, .flush, .straight, .straightFlush])
    }
    
    func testRoyalFlush() {
        self.test("10S JS QS KS AS", [.highCard, .flush, .straight, .straightFlush, .royalFlush])
        self.test("10H JH QH KH AH", [.highCard, .flush, .straight, .straightFlush, .royalFlush])
    }
    
    // MARK: - Edge Cases
    
    func testEmptyHand() {
        self.test("", [])
    }
    
    func testSingleCard() {
        self.test("AS", [.highCard])
        self.test("2C", [.highCard])
    }
    
    func testNonConsecutiveCards() {
        self.test("2S 4H 6C 8D 10H", [.highCard])
        self.test("AS 3H 5C 7D 9H", [.highCard])
    }
    
    func testAlmostStraight() {
        self.test("2S 3H 4C 5D 7H", [.highCard]) // Missing 6
        self.test("10S JH QC AD 2H", [.highCard]) // Gap between K and A
    }
    
    func testAlmostFlush() {
        self.test("2S 5S 7S 9S JH", [.highCard]) // 4 spades + 1 heart
    }
    
    // MARK: - Larger Hands (6-8 cards)
    
    func testSixCardHand() {
        // Contains both a flush and a straight
        self.test("2S 3S 4S 5S 6S 7H", [.highCard, .flush, .straight, .straightFlush])
        
        // Contains full house
        self.test("AS AH AC KD KH QC", [.highCard, .onePair, .twoPair, .threeOfAKind, .fullHouse])
        
        // Contains four of a kind
        self.test("2S 2H 2C 2D 5H 7C", [.highCard, .onePair, .twoPair, .threeOfAKind, .fourOfAKind])
    }
    
    func testSevenCardHand() {
        // Contains multiple pairs
        self.test("2S 2H 3C 3D 4H 4S 5C", [.highCard, .onePair, .twoPair])
        
        // Contains straight flush
        self.test("2S 3S 4S 5S 6S 7H 8C", [.highCard, .flush, .straight, .straightFlush])
        
        // Contains full house with extra cards
        self.test("AS AH AC KD KH QC JH", [.highCard, .onePair, .twoPair, .threeOfAKind, .fullHouse])
    }
    
    func testEightCardHand() {
        // Contains royal flush with extra cards
        self.test("10S JS QS KS AS 2H 3C 4D", [.highCard, .flush, .straight, .straightFlush, .royalFlush])
        
        // Contains multiple different hands
        self.test("2S 2H 3C 3D 4H 4S 5C 5D", [.highCard, .onePair, .twoPair])
        
        // Contains four of a kind with extra cards
        self.test("AS AH AC AD KS KH QC JD", [.highCard, .onePair, .twoPair, .threeOfAKind, .fullHouse, .fourOfAKind])
        
        // Complex hand with flush and pairs
        self.test("2S 3S 4S 5S 7S 2H 3H 4H", [.highCard, .onePair, .twoPair, .flush])
    }
    
    // MARK: - Special Straight Cases
    
    func testAceLowStraight() {
        self.test("AS 2H 3C 4D 5S", [.highCard, .straight])
    }
    
    func testAceHighStraight() {
        self.test("10S JH QC KD AS", [.highCard, .straight])
    }
    
    func testAceLowStraightFlush() {
        self.test("AS 2S 3S 4S 5S", [.highCard, .flush, .straight, .straightFlush])
    }
    
    func testNotAceWrapAroundStraight() {
        // Q, K, A, 2, 3 is not a valid straight
        self.test("QS KH AC 2D 3S", [.highCard])
    }
    
    // MARK: - Helper Method
    
    private func test(
        _ handString: String,
        _ expectedHands: Set<PokerHandKind>,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let hand = try! Card.makeHand(handString)
        let resolver = PokerHandResolver()
        let result = resolver.pokerHands(in: hand)
        XCTAssertEqual(result, expectedHands, file: file, line: line)
    }
}
