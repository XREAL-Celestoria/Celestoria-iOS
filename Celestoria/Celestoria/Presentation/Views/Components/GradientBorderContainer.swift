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
            RoundedRectangle(cornerRadius: 44)
                .fill(Color.NebulaBlack)
                .overlay(
                    RoundedRectangle(cornerRadius: 44)
                        .stroke(
                            LinearGradient.GradientMain,
                            lineWidth: 8
                        )
                )
            
            content
                .padding(16)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 44))
        }
        .padding(4)
    }
}
