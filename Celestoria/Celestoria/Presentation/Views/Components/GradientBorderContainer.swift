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
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.NebulaBlack)
                .clipShape( 
                    RoundedRectangle(cornerRadius: 46)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 46)
                        .stroke(
                            LinearGradient.GradientMain,
                            lineWidth: 8
                        )
                )
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
        }
        .ignoresSafeArea(.all, edges: .bottom)
    }
}
