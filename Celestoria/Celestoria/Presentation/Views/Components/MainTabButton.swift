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
        GeometryReader { geometry in
            VStack {
                Button(action: action) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient.MainTabButtonBackground
                            )
                            .shadow(color: .black.opacity(0.18), radius: 49.92025, x: 0, y: 4.16002)
                            .overlay(
                                Circle()
                                    .inset(by: 1.34)
                                    .stroke(
                                        LinearGradient.MainTabButtonStroke,
                                        lineWidth: 2.69
                                    )
                            )
                        
                        Image(imageName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 50, height: 50)
                            .foregroundColor(.NebulaWhite)
                    }
                    .frame(width: geometry.size.width, height: geometry.size.width)
                }
                .buttonStyle(MainTabButtonStyle())
                
                Spacer()
                    .frame(height: 16)  
                
                Text(text)
                    .font(.system(size: 19, weight: .bold))
                    .foregroundColor(.NebulaWhite)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.NebulaBlack)
        }
    }
}

struct MainTabButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}
