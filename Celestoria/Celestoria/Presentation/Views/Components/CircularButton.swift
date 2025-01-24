//
//  CircularButton.swift
//  Celestoria
//
//  Created by Park Seyoung on 1/24/25.
//

import SwiftUI

struct CircularButton: View {
    let action: () -> Void
    let buttonImageString : String
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(Color(hex: "E7E7E7").opacity(0.2))
                    .frame(width: 44, height: 44)
                
                Image(systemName: buttonImageString)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .foregroundColor(.NebulaWhite)
            }
        }
        .background(.clear)
        .buttonStyle(CircularButtonStyle())
    }
}

struct CircularButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
    }
}
