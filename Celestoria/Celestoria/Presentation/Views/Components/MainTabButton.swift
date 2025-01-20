//
//  MainButton.swift
//  Celestoria
//
//  Created by Park Seyoung on 1/20/25.
//

import SwiftUI

struct MainTabButton: View {
    let imageName: String
    let text: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            GeometryReader { geometry in
                VStack {
                    ZStack {
                        Circle()
                            .fill(Color.NebulaBlack)
                            .overlay(
                                Circle()
                                    .fill(LinearGradient.MainTabButtonBackground.opacity(0.3))
                            )
                            .shadow(color: Color.black.opacity(0.18), radius: 50, x: 0, y: 4)
                            .overlay(
                                Circle()
                                    .stroke(
                                        LinearGradient.MainTabButtonStroke,
                                        lineWidth: 2.69
                                    )
                            )
                        Circle()
                            .fill(.ultraThinMaterial)
                            .opacity(0.2)
                        
                        Image(systemName: imageName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: geometry.size.width * 0.48, height: geometry.size.height * 0.48)
                            .foregroundColor(.NebulaWhite)
                    }
                    .frame(width: geometry.size.width, height: geometry.size.width)
                    Spacer()
                        .frame(height: geometry.size.height * 1)  
                    Text(text)
                        .font(.system(size: 19, weight: .bold))
                        .foregroundColor(.NebulaWhite)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Color.NebulaBlack)
        .buttonStyle(PlainButtonStyle())
    }
}

