//
//  Card.swift
//  DiscarderKit
//
//  Created by Andrii Zinoviev on 07.06.2025.
//

public enum Suit: Int, Sendable, Hashable, CustomStringConvertible, CaseIterable {
    case spades = 0
    case hearts
    case diamonds
    case clubs
    
    init?(string: String) {
        switch string {
        case "S":
            self = .spades
        case "H":
            self = .hearts
        case "D":
            self = .diamonds
        case "C":
            self = .clubs
        default:
            return nil
        }
    }
    
    public var description: String {
        switch self {
        case .spades:
            "S"
        case .hearts:
            "H"
        case .diamonds:
            "D"
        case .clubs:
            "C"
        }
    }
}

public struct Rank: Sendable, Hashable, CustomStringConvertible, Comparable, ExpressibleByIntegerLiteral, CaseIterable {
    private static let namedRanks: [Rank: String] = [
        .jack: "J",
        .queen: "Q",
        .king: "K",
        .ace: "A",
    ]
    
    public let index: Int
    
    public init(index: Int) {
        self.index = index
    }
    
    public init(integerLiteral value: IntegerLiteralType) {
        self.init(index: value)
    }
    
    public var description: String {
        if let namedRank = Self.namedRanks[self] {
            return namedRank
        }
        else {
            return String(self.index)
        }
    }

    public static func < (lhs: Rank, rhs: Rank) -> Bool {
        lhs.index < rhs.index
    }
    
    public static let jack = Rank(index: 11)
    public static let queen = Rank(index: 12)
    public static let king = Rank(index: 13)
    public static let ace = Rank(index: 14)
    
    public static var allCases: [Rank] {
        (2...14).map(Rank.init(index:))
    }
    
    public init?(string: String) {
        for (namedRank, rankString) in Self.namedRanks {
            if rankString == string {
                self = namedRank
                return
            }
        }
        
        if let index = Int(string) {
            self = Self(index: index)
        }
        else {
            return nil
        }
    }
}

public struct Card: Hashable, CustomStringConvertible, Sendable, Comparable {
    public let rank: Rank
    public let suit: Suit
    
    public var description: String {
        "\(self.rank)\(self.suit)"
    }
    
    public static func < (lhs: Card, rhs: Card) -> Bool {
        if lhs.suit == rhs.suit {
            return lhs.rank < rhs.rank
        }
        
        return lhs.suit.rawValue < rhs.suit.rawValue
    }
}

extension String {
    func paddedToLength(_ length: Int) -> String {
        self.count >= length ? self : String(repeating: " ", count: length - self.count) + self
    }
}

extension Card {
    public init?(string value: some StringProtocol) {
        let rankString = String(value.prefix(value.count - 1))
        let suitString = String(value.suffix(1))
        
        guard let rank = Rank(string: rankString) else {
            return nil
        }
        
        guard let suit = Suit(string: suitString) else {
            return nil
        }
        
        self.init(rank: rank, suit: suit)
    }
    
    public static func makeHand(_ string: String) throws -> [Card] {
        string.split(separator: " ").map { value in
            Card(string: value)!
        }
    }
}

extension Card: ExpressibleByStringLiteral {
    public init(stringLiteral value: StringLiteralType) {
        self.init(string: value)!
    }
}
