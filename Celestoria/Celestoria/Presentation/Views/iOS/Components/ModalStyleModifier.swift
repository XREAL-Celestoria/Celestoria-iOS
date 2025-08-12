//
//  ModalStyleModifier.swift
//  Celestoria
//
//  Created by Seyoung Park on 8/2/25.
//

import SwiftUI

// MARK: - Modal Style Modifier
struct ModalStyleModifier: ViewModifier {
    let cornerRadius: CGFloat
    let isExpanded: Bool
    let corners: UIRectCorner
    
    init(cornerRadius: CGFloat = 24, isExpanded: Bool = false, corners: UIRectCorner = .allCorners) {
        self.cornerRadius = cornerRadius
        self.isExpanded = isExpanded
        // 확장 상태일 때는 위쪽 모서리만, 축소 상태일 때는 모든 모서리
        self.corners = isExpanded ? [.topLeft, .topRight] : .allCorners
    }
    
    func body(content: Content) -> some View {
        content
            .background(
                Group {
                    if isExpanded {
                        // 확대 상태: BackgroundBlack
                        Colors.BackgroundBlack
                    } else {
                        // 축소 상태: 기존 그라디언트
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.141, green: 0.263, blue: 0.388), // #244363
                                Color(red: 0.094, green: 0.098, blue: 0.145) // #181925
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.4, green: 0.6, blue: 0.9).opacity(0.2),
                                Color(red: 0.3, green: 0.5, blue: 0.8).opacity(0.1)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .cornerRadius(cornerRadius, corners: corners)
            .shadow(
                color: Color(red: 0.4, green: 0.7, blue: 1).opacity(0.5), 
                radius: 6,
                x: 0, 
                y: 0
            )
            .shadow(
                color: Color(red: 0.4, green: 0.7, blue: 1).opacity(0.3),
                radius: 8,
                x: 0, 
                y: 0
            )
    }
} 
