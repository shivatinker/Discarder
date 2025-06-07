//
//  MCSimulator.swift
//  DiscarderKit
//
//  Created by Andrii Zinoviev on 07.06.2025.
//

import Combine

public protocol MonteCarloAlgorithm {
    associatedtype Output
    
    static var initialOutput: Output { get }
    
    func performIteration(
        random: inout some RandomNumberGenerator,
        output: inout Output,
        iterations: Int
    )
}

public protocol MCSimulatorDelegate<Output>: AnyObject {
    associatedtype Output
    
    func handleUpdate(_ output: Output, iteration: Int)
}

public actor MCSimulator<Algorithm: MonteCarloAlgorithm> {
    private var random: RandomNumberGenerator
    
    private weak var delegate: (any MCSimulatorDelegate<Algorithm.Output>)?
    
    private let algorithm: Algorithm
    private var iterations: Int = 0
    
    private var output: Algorithm.Output
    
    public init(
        seed: UInt64,
        algorithm: Algorithm
    ) {
        self.random = SplitMix64(seed: seed)
        self.algorithm = algorithm
        self.output = Algorithm.initialOutput
    }
    
    public func setDelegate(_ delegate: some MCSimulatorDelegate<Algorithm.Output>) {
        self.delegate = delegate
    }
    
    public func iterate(count: Int) async throws {
        for _ in 0..<count {
            try Task.checkCancellation()
            self.performIteration()
        }
    }
    
    private func performIteration() {
        self.algorithm.performIteration(
            random: &self.random,
            output: &self.output,
            iterations: self.iterations + 1
        )
            
        self.iterationCompeted()
    }
    
    private func iterationCompeted() {
        self.iterations += 1
        
        if self.iterations.isMultiple(of: 100) {
            self.delegate?.handleUpdate(self.output, iteration: self.iterations)
        }
    }
}

private struct SplitMix64: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        self.state = seed
    }

    mutating func next() -> UInt64 {
        self.state &+= 0x9E3779B97F4A7C15
        var z: UInt64 = self.state
        z = (z ^ (z &>> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z &>> 27)) &* 0x94D049BB133111EB
        return z ^ (z &>> 31)
    }
}
