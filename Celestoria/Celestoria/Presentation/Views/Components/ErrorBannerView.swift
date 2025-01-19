//
//  ErrorBannerView.swift
//  Celestoria
//
//  Created by Park Seyoung on 1/20/25.
//

import SwiftUI

struct ErrorBannerView: View {
    let message: String

    var body: some View {
        Text(message)
            .padding()
            .background(Color.red.opacity(0.8))
            .foregroundColor(.white)
            .cornerRadius(10)
            .transition(.move(edge: .top))
            .animation(.easeInOut, value: message)
            .padding(.top, 20)
    }
}
