//
//  Multiset.swift
//  DiscarderKit
//
//  Created by Andrii Zinoviev on 07.06.2025.
//

public struct Multiset<Element: Hashable>: Equatable {
    private var counts: [Element: Int] = [:]
    
    public mutating func insert(_ element: Element) {
        self.counts[element, default: 0] += 1
    }
    
    public mutating func insert(_ sequence: some Sequence<Element>) {
        for element in sequence {
            self.insert(element)
        }
    }
    
    public mutating func remove(_ element: Element) {
        guard let count = self.counts[element] else { return }
        
        if count == 1 {
            self.counts[element] = nil
        }
        else {
            self.counts[element] = count - 1
        }
    }
    
    public mutating func remove(_ other: Multiset<Element>) {
        for (element, count) in other {
            for _ in 0..<count {
                self.remove(element)
            }
        }
    }
    
    public mutating func remove(_ other: some Sequence<Element>) {
        for element in other {
            self.remove(element)
        }
    }
    
    public func contains(_ other: some Sequence<Element>) -> Bool {
        let multiset = Multiset(other)
        return self.contains(multiset)
    }
    
    public func contains(_ other: Multiset<Element>) -> Bool {
        for (element, count) in other {
            if self.countOf(element) < count {
                return false
            }
        }
        return true
    }

    public func contains(_ element: Element) -> Bool {
        self.counts[element, default: 0] > 0
    }
    
    public func countOf(_ element: Element) -> Int {
        self.counts[element, default: 0]
    }
    
    public var count: Int {
        self.counts.reduce(into: 0) { $0 += $1.value }
    }
    
    public var isEmpty: Bool {
        self.counts.isEmpty
    }
    
    public var allElements: some Sequence<Element> {
        self.counts.lazy.flatMap { element, count in
            repeatElement(element, count: count)
        }
    }
}

extension Multiset: Sequence {
    public func makeIterator() -> [Element: Int].Iterator {
        self.counts.makeIterator()
    }
}

extension Multiset: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: Element...) {
        self.init(elements)
    }
    
    public init(_ other: some Sequence<Element>) {
        self.counts = other.reduce(into: [:]) { counts, element in
            counts[element, default: 0] += 1
        }
    }
}
