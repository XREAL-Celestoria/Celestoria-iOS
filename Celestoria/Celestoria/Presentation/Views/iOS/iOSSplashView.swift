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
            Image("splash")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isAnimating)
        }
        .onAppear {
            isAnimating = true
        }
    }
}
