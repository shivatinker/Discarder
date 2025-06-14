//
//  ContentView.swift
//  Discarder
//
//  Created by Andrii Zinoviev on 07.06.2025.
//

import DiscarderKit
import SwiftUI

struct ContentView: View {
    @ObservedObject
    var model: MainViewModel
    
    var body: some View {
        HStack {
            VStack {
                HStack {
                    Button("Clear deck") {
                        self.model.clearDeck()
                    }
                    
                    Button("Reset") {
                        self.model.reset()
                    }
                }
                
                AllCardsView(action: self.model.addCardToDeck)
             
                DeckView(
                    deck: self.model.deck,
                    action: self.model.addCardToHand,
                    removeAction: self.model.removeCardFromDeck
                )
                
                HandView(
                    maxSize: self.model.handSize,
                    cards: self.model.hand,
                    discardedCards: self.model.discardedCards,
                    discardHandler: self.model.toggleDiscardCard,
                    removeHandler: self.model.removeCardFromHand
                )
            }
            .frame(minWidth: 700)
            
            Divider()
            
            ResultView(isLoading: self.model.isLoading, result: self.model.result)
                .frame(width: 400)
        }
        .padding()
        .fixedSize(horizontal: false, vertical: true)
    }
}

struct ResultView: View {
    let isLoading: Bool
    let result: DiscarderResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Iteration #\(self.result.iterations)")
                .font(.title2)
                .monospacedDigit()
            
            if self.result.iterations == 0 {
                Text("No iterations yet")
                    .foregroundStyle(.secondary)
            }
            else {
                ForEach(self.result.allOuts, id: \.0) { hand, outs in
                    ResultCard(
                        hand: hand,
                        outs: outs,
                        percentage: Double(outs) / Double(self.result.iterations) * 100
                    )
                }
            }
        }
        .overlay {
            if self.isLoading {
                ProgressView()
                    .scaleEffect(0.5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .frame(maxHeight: .infinity, alignment: .topLeading)
    }
}

struct ResultCard: View {
    let hand: PokerHandKind
    let outs: Int64
    let percentage: Double
    
    var body: some View {
        HStack(alignment: .center) {
            Text(self.hand.description)
                .font(.headline)
            
            Spacer()
            
            HStack(spacing: 8) {
                Text("\(String(format: "%.3f", self.percentage))%")
                    .font(.title3)
                    .foregroundStyle(.cyan)
                    .bold()
                    .monospacedDigit()
                    .frame(width: 100, alignment: .trailing)
                
                Text("\(self.outs)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                    .frame(width: 100, alignment: .leading)
                    .fixedSize(horizontal: true, vertical: false)
            }
        }
    }
}

#Preview {
    ContentView(
        model: MainViewModel()
    )
    .fixedSize()
}

// #Preview {
//    ResultView(isLoading: true, result: .test)
//        .frame(width: 300)
// }
