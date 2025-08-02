//
//  iOSHeaderView.swift
//  Celestoria
//
//  Created by Minjun Kim on 7/20/25.
//


import SwiftUI

struct iOSHeaderView: View {
    var title: String
    var subtitle: String
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.system(size: 50, weight: .bold, design: .default))
                .foregroundStyle(LinearGradient.GradientMain)
                .multilineTextAlignment(.center)
            
            Text(subtitle)
                .font(.system(size: 15, weight: .semibold, design: .default))
                .foregroundStyle(LinearGradient.GradientMain)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
}
