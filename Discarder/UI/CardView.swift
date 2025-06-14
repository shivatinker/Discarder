//
//  CardView.swift
//  Discarder
//
//  Created by Andrii Zinoviev on 14.06.2025.
//

import DiscarderKit
import SwiftUI

struct CardView: View {
    @State
    private var isHovered: Bool = false
    
    let card: Card
    let isDiscarded: Bool
    let action: () -> Void
    let removeAction: (() -> Void)?
    
    init(
        card: Card,
        isDiscarded: Bool,
        action: @escaping () -> Void,
        removeAction: (() -> Void)? = nil
    ) {
        self.card = card
        self.isDiscarded = isDiscarded
        self.action = action
        self.removeAction = removeAction
    }
    
    var body: some View {
        CardImage(.card(self.card))
            .overlay {
                if self.isHovered {
                    Rectangle()
                        .fill(Color.blue.opacity(0.2))
                }
            }
            .overlay {
                if self.isDiscarded {
                    Rectangle()
                        .fill(Color.red.opacity(0.2))
                }
            }
            .onHover { self.isHovered = $0 }
            .onTapGesture {
                self.action()
            }
            .overlay {
                if let removeAction {
                    Image(systemName: "xmark")
                        .foregroundStyle(.red)
                        .padding(1)
                        .background {
                            Circle().fill(Color.red.opacity(0.2))
                        }
                        .contentShape(Circle())
                        .onTapGesture {
                            removeAction()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                }
            }
    }
}

#Preview {
    CardView(
        card: "AS",
        isDiscarded: false,
        action: { print("action") },
        removeAction: { print("remove") }
    )
    .padding()
}
