//
//  HeaderView.swift
//  Celestoria
//
//  Created by Park Seyoung on 1/20/25.
//

import SwiftUI

struct HeaderView: View {
    var title: String
    var subtitle: String
    
    var body: some View {
        VStack(spacing: 10) {
            Text(title)
                .font(.system(size: 96, weight: .bold, design: .default))
                .foregroundStyle(LinearGradient.GradientMain)
                .multilineTextAlignment(.center)
            
            Text(subtitle)
                .font(.system(size: 29, weight: .bold, design: .default))
                .foregroundStyle(LinearGradient.GradientMain)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.top, 20)
    }
}
