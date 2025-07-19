//
//  iOSHeaderView.swift
//  Celestoria
//
//  Created by Assistant on 2025/07/19.
//

import SwiftUI

struct iOSHeaderView: View {
    var title: String
    var subtitle: String
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.system(size: 48, weight: .bold, design: .default))
                .foregroundStyle(LinearGradient.GradientMain)
                .multilineTextAlignment(.center)
            
            Text(subtitle)
                .font(.system(size: 18, weight: .semibold, design: .default))
                .foregroundStyle(LinearGradient.GradientMain)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.top, 20)
    }
}