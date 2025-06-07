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
    
    func run() async throws {
        let hand = try Card.makeHand(self.hand)
        
        let algorithm = DiscarderAlgorithm(
            hand: hand,
            deck: ["AH", "2D"],
            drawCount: 1
        )
        
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
