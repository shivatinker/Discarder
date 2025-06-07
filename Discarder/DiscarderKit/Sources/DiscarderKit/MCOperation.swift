//
//  MCOperation.swift
//  DiscarderKit
//
//  Created by Andrii Zinoviev on 07.06.2025.
//

import Foundation

final class MCOperation<Algorithm: MonteCarloAlgorithm>: Operation, @unchecked Sendable {
    private let algorithm: Algorithm
    private var random: RandomNumberGenerator
    private let iterations: Int
    private let batchSize: Int
    
    private var output: Algorithm.Output
    
    private var completedIterations: Int = 0
    private var batchIterations: Int = 0
    
    var batchHandler: (@MainActor (Algorithm.Output) -> Void)?
    var completionHandler: (@MainActor () -> Void)?
    
    init(
        algorithm: Algorithm,
        seed: UInt64,
        iterations: Int,
        batchSize: Int
    ) {
        self.algorithm = algorithm
        self.random = SplitMix64(seed: seed)
        self.iterations = iterations
        self.batchSize = batchSize
        self.output = Algorithm.initialOutput
    }
    
    override func main() {
        defer {
            DispatchQueue.main.async {
                self.completionHandler?()
            }
        }
        
        let context = self.algorithm.makeContext()
        
        while self.completedIterations < self.iterations {
            if self.isCancelled {
                return
            }
            
            self.algorithm.performIteration(
                context: context,
                random: &self.random,
                output: &self.output
            )
            
            self.batchIterations += 1
            self.completedIterations += 1
            
            if self.batchIterations == self.batchSize {
                self.reportBatch()
            }
        }
        
        self.reportBatch()
    }
    
    private func reportBatch() {
        guard self.batchIterations > 0 else {
            return
        }
        
        let output = self.output
        
        DispatchQueue.main.async {
            self.batchHandler?(output)
        }
        
        self.batchIterations = 0
        self.output = Algorithm.initialOutput
    }
}
