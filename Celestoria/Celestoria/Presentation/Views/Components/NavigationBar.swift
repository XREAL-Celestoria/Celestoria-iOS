//
//  NavigationBar.swift
//  Celestoria
//
//  Created by Park Seyoung on 1/22/25.
//

import SwiftUI

struct NavigationBar: View {
    let title: String
    let buttonImageString: String
    let action: () -> Void
    
    var body: some View {
        HStack {
            Button(action: action) {
                ZStack {
                    Circle()
                        .fill(Color(hex: "E7E7E7").opacity(0.05))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: buttonImageString)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .foregroundColor(.NebulaWhite)
                }
            }
            .buttonStyle(CircularButtonStyle())
            
            Text(title)
                .font(.system(size: 29, weight: .bold))
                .foregroundColor(.NebulaWhite)
                .padding(.leading, 24)
            
            Spacer()
        }
        .background(Color.NebulaBlack)
        .padding(.horizontal, 28)
        .padding(.top, 28)
    }
}

struct CircularButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
    }
}
