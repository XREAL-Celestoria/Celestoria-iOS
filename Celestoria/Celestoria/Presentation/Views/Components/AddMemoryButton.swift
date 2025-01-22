//
//  AddMemoryButton.swift
//  Celestoria
//
//  Created by Park Seyoung on 1/20/25.
//

import SwiftUI

struct AddMemoryButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image("AddMemoryStar")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                Text("Add Memory Star")
                    .font(.system(size: 22, weight: .bold, design: .default))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .background(LinearGradient.GradientSub)
            .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
        .foregroundColor(.NebulaBlack)
    }
}
