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
        GeometryReader { geometry in
            VStack {
                Spacer()
                    .frame(height: geometry.size.height * 0.24)
                
                Image("splashSquareImage")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 150, height: 150)
                
                Spacer()
                    .frame(height: 60)
                
                iOSHeaderView(title: "Celestoria", subtitle: "Spatial Video Social Network")
                
                Spacer()
            }
        }
        .background(Colors.backgroundMain)  // 배경색 추가
        .onAppear {
            isAnimating = true
        }
    }
}
