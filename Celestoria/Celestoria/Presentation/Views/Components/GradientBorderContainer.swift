//
//  GradientBorderContainer.swift
//  Celestoria
//
//  Created by Park Seyoung on 1/20/25.
//

import SwiftUI

struct GradientBorderContainer: View {
    let content: AnyView
    
    init<Content: View>(@ViewBuilder content: () -> Content) {
        self.content = AnyView(content())
    }
    
    var body: some View {
        ZStack {
            // 가끔 배경 투명해지는 버그 있어서 순서 이렇게
            Color.NebulaBlack
                .ignoresSafeArea()

            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipShape( 
                    RoundedRectangle(cornerRadius: 44)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 44)
                        .stroke(
                            LinearGradient.GradientMain,
                            lineWidth: 8
                        )
                )
        }
        .padding(4)
    }
}
