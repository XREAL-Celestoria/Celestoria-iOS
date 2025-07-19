//
//  iOSMainButton.swift
//  Celestoria
//
//  Created by Minjun Kim on 7/20/25.
//


//
//  iOSMainButton.swift
//  Celestoria
//
//  Created by Claude on 1/19/25.
//

import Foundation
import AudioToolbox
import SwiftUI

struct iOSMainButton: View {
    let title: String
    let action: () -> Void
    let isEnabled: Bool
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(isEnabled ? .NebulaBlack : .NebulaWhite)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(isEnabled ?
                            AnyShapeStyle(LinearGradient.GradientSub) :
                                AnyShapeStyle(Color.NebulaWhite.opacity(0.1)))
                .cornerRadius(12)
        }
        .buttonStyle(iOSMainButtonStyle())
        .padding(.horizontal, 24)
    }
}


struct iOSMainButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .onChange(of: configuration.isPressed) { oldValue, newValue in
                if newValue {
                    AudioServicesPlaySystemSound(1104)
                }
            }
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}