//
//  MCSimulator.swift
//  DiscarderKit
//
//  Created by Andrii Zinoviev on 07.06.2025.
//

import Combine
import Foundation

public protocol MonteCarloAlgorithm {
    associatedtype Output: Sendable
    associatedtype Context: AnyObject
    
    static var initialOutput: Output { get }
    
    func makeContext() -> Context
    
    func performIteration(
        context: Context,
        random: inout some RandomNumberGenerator,
        output: inout Output
    )
    
    func combine(output: Output, into other: inout Output)
}

@MainActor
public protocol MCSimulatorDelegate<Output>: AnyObject {
    associatedtype Output: Sendable
    
    func handleUpdate(_ output: Output)
}

@MainActor
public final class MCSimulator<Algorithm: MonteCarloAlgorithm> {
    private let threadCount = ProcessInfo.processInfo.activeProcessorCount
    
    private var random: RandomNumberGenerator
    
    private weak var delegate: (any MCSimulatorDelegate<Algorithm.Output>)?
    
    private let algorithm: Algorithm
    
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
    
    private let clock = ContinuousClock()
    
    public func run(iterations: Int) async throws {
        let startTime = self.clock.now
        
        let queue = OperationQueue()
        
        queue.maxConcurrentOperationCount = self.threadCount
        
        try await withTaskCancellationHandler(
            operation: {
                try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                    self.run(on: queue, iterations: iterations) {
                        let endTime = self.clock.now
                        print(endTime - startTime)
                        
                        if Task.isCancelled {
                            continuation.resume(throwing: CancellationError())
                        }
                        else {
                            continuation.resume()
                        }
                    }
                }
            },
            onCancel: {
                queue.cancelAllOperations()
            }
        )
    }
    
    private func run(
        on queue: OperationQueue,
        iterations: Int,
        completionHandler: @escaping () -> Void
    ) {
        let threadIterations = self.splitIterations(n: iterations, k: self.threadCount)
        
        var completedThreads: Set<Int> = []
        
        for (index, threadIterationCount) in threadIterations.enumerated() {
            print("Thread #\(index): \(threadIterationCount)")
            
            let operation = MCOperation(
                algorithm: self.algorithm,
                seed: UInt64.random(in: 0..<UInt64.max, using: &self.random),
                iterations: threadIterationCount,
                batchSize: 30_000
            )
            
            operation.batchHandler = { [weak self] batchOutput in
                guard let self else { return }
                
                self.algorithm.combine(output: batchOutput, into: &self.output)
                self.delegate?.handleUpdate(self.output)
            }
            
            operation.completionHandler = {
                print("Thread #\(index): DONE")
                completedThreads.insert(index)
                
                if completedThreads.count == threadIterations.count {
                    completionHandler()
                }
            }
            
            queue.addOperation(operation)
        }
    }
    
    private func splitIterations(n: Int, k: Int) -> [Int] {
        let base = n / k
        let remainder = n % k
        var result: [Int] = []
        var current = 0

        for i in 0..<k {
            let count = base + (i < remainder ? 1 : 0)
            result.append(count)
            current += count
        }

        return result
    }
}

struct SplitMix64: RandomNumberGenerator {
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
