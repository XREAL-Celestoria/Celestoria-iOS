//
//  iOSSplashView.swift
//  Celestoria-iOS
//
//  Created by Seyoung Park on 8/2/25.
//

import SwiftUI

struct iOSSplashView: View {
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            Colors.backgroundMain
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // 앱 아이콘
                Image("Logo")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 168, maxHeight: 168)
                    .scaleEffect(isAnimating ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isAnimating)
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}
