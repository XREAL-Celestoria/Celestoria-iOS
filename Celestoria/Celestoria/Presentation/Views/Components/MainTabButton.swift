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
                            .fill(
                                LinearGradient(
                                    stops: [
                                        .init(color: .white.opacity(0.5), location: 0.00),
                                        .init(color: Color(red: 0.92, green: 0.92, blue: 0.92).opacity(0.37), location: 0.20),
                                        .init(color: Color(red: 0.88, green: 0.88, blue: 0.88).opacity(0.29), location: 0.28),
                                        .init(color: Color(red: 0.83, green: 0.83, blue: 0.83).opacity(0.21), location: 0.40),
                                        .init(color: Color(red: 0.81, green: 0.81, blue: 0.81).opacity(0.18), location: 0.48),
                                        .init(color: Color(red: 0.79, green: 0.79, blue: 0.79).opacity(0.14), location: 0.54),
                                        .init(color: Color(red: 0.78, green: 0.78, blue: 0.78).opacity(0.13), location: 0.59),
                                        .init(color: Color(red: 0.77, green: 0.77, blue: 0.77).opacity(0.1), location: 0.67),
                                    ],
                                    startPoint: UnitPoint(x: -0.21, y: -0.17),
                                    endPoint: UnitPoint(x: 1, y: 1)
                                )
                            )
                            .shadow(color: .black.opacity(0.18), radius: 49.92025, x: 0, y: 4.16002)
                            .overlay(
                                Circle()
                                    .inset(by: 1.34)
                                    .stroke(
                                        LinearGradient(
                                            stops: [
                                                .init(color: .white.opacity(0.2), location: 0.1414),
                                                .init(color: .clear, location: 0.4767),
                                                .init(color: .white.opacity(0.2), location: 0.8263)
                                            ],
                                            startPoint: UnitPoint(x: 0, y: 0),
                                            endPoint: UnitPoint(x: 1, y: 1)
                                        ),
                                        lineWidth: 2.69
                                    )
                            )
                        
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

