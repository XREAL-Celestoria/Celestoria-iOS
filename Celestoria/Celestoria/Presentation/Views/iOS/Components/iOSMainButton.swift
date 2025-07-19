//
//  iOSMainButton.swift
//  Celestoria
//
//  Created by Assistant on 2025/07/19.
//

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
                .frame(height: 52)
                .background(isEnabled ?
                           AnyShapeStyle(LinearGradient.GradientSub) :
                               AnyShapeStyle(Color.NebulaWhite.opacity(0.1)))
                .cornerRadius(12)
        }
        .disabled(!isEnabled)
    }
}