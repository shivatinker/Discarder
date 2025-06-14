//
//  MainViewModel.swift
//  Discarder
//
//  Created by Andrii Zinoviev on 14.06.2025.
//

import DiscarderKit
import IdentifiedCollections
import SwiftUI

@MainActor
final class MainViewModel: ObservableObject {
    @Published private(set) var result = DiscarderResult()
    @Published private(set) var deck = Deck.makeStandard()
    @Published private(set) var handSize = 8
    @Published private(set) var isLoading = false
    @Published private(set) var hand: IdentifiedArrayOf<DeckCard> = []
    @Published private(set) var discardedCards: Set<UUID> = []
    
    init() {
        self.updateResult()
    }
    
    func addCardToDeck(_ card: Card) {
        self.deck.cards.append(DeckCard(id: UUID(), card: card))
        
        self.updateResult()
    }
    
    func removeCardFromDeck(id: UUID) {
        self.deck.cards[id: id] = nil
        
        self.updateResult()
    }
    
    func addCardToHand(id: UUID) {
        guard self.hand.count < self.handSize else {
            return
        }
        
        guard let card = self.deck.cards.remove(id: id) else {
            assertionFailure()
            return
        }
        
        self.hand.append(card)
        
        self.updateResult()
    }
    
    func removeCardFromHand(id: UUID) {
        guard let card = self.hand.remove(id: id) else {
            assertionFailure()
            return
        }
        
        self.deck.cards.append(card)
        
        self.updateResult()
    }
    
    func clearDeck() {
        self.deck.cards.removeAll()
        
        self.updateResult()
    }
    
    func reset() {
        self.hand.removeAll()
        self.deck = Deck.makeStandard()
        
        self.updateResult()
    }
    
    func toggleDiscardCard(_ id: UUID) {
        if self.discardedCards.contains(id) {
            self.discardedCards.remove(id)
        }
        else {
            self.discardedCards.insert(id)
        }
        
        self.updateResult()
    }
    
    private func updateResult() {
        Task {
            let discarder = Discarder(deck: self.deck, handSize: self.handSize, seed: 42)
            
            let hand = self.hand.elements
                .filter { false == self.discardedCards.contains($0.id) }
                .map(\.card)
            
            await discarder.run(
                hand: hand,
                maxIterations: 1_000_000
            ) { result in
                DispatchQueue.main.async {
                    self.result = result
                }
            }
        }
    }
}
