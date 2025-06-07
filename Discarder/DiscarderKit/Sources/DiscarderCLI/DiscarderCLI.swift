//
//  DiscarderCLI.swift
//  DiscarderKit
//
//  Created by Andrii Zinoviev on 07.06.2025.
//

import ArgumentParser
import DiscarderKit

@main
struct DiscarderCLI: AsyncParsableCommand {
    @Argument
    var hand: String
    
    @Argument
    var discard: String
    
    func run() async throws {
        let hand = try Multiset(Card.makeHand(self.hand))
        let discard = try Multiset(Card.makeHand(self.discard))
        
        let algorithm = DiscarderAlgorithm(hand: hand, discards: discard)
        
        let simulator = MCSimulator(
            seed: 42,
            algorithm: algorithm
        )
        
        let delegate = SimulatorDelegate()
        simulator.delegate = delegate
        
        try await simulator.iterate(count: 1_000_000)
    }
}

private final class SimulatorDelegate: MCSimulatorDelegate {
    typealias Output = DiscarderResult
    
    func handleUpdate(_ output: DiscarderResult, iteration: Int) {
        print("---- Processed \(iteration) iterations")
        print(output)
    }
}
