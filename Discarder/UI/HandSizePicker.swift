//
//  HandSizePicker.swift
//  Discarder
//
//  Created by Andrii Zinoviev on 14.06.2025.
//

import SwiftUI

struct HandSizePicker: View {
    @Binding var handSize: Int
    
    var body: some View {
        HStack {
            Text("Hand Size")
            
            SmallButton(imageName: "minus") {
                self.handSize -= 1
            }
            
            Text("\(self.handSize)")
            
            SmallButton(imageName: "plus") {
                self.handSize += 1
            }
        }
    }
}

struct SmallButton: View {
    let imageName: String
    let action: () -> Void
    
    var body: some View {
        Image(systemName: self.imageName)
            .frame(width: 24, height: 24)
            .contentShape(Rectangle())
            .onTapGesture {
                self.action()
            }
            .background(Color.gray.opacity(0.2))
    }
}
