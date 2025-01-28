//
//  MainButton.swift
//  Celestoria
//
//  Created by Park Seyoung on 1/26/25.
//

import Foundation
import SwiftUI
import Vision

struct MainButton: View {
    let title: String
    let action: () -> Void
    let isEnabled: Bool
    
    var body: some View {
        Button(action: action) {
            Text(title) // Dynamic title
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(isEnabled ? .NebulaBlack : .NebulaWhite)
                .frame(width: 380, height: 64)
                .background(isEnabled ?
                            AnyShapeStyle(LinearGradient.GradientSub) :
                                AnyShapeStyle(Color.NebulaWhite.opacity(0.1)))
                .cornerRadius(16)
        }
        .hoverEffect(.automatic)
//        .buttonStyle(MainButtonStyle())
    }
}


struct MainButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}
