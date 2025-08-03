//
//  LoadingView.swift
//  Celestoria
//
//  Created by Assistant on 2025/07/20.
//

import SwiftUI

struct LoadingView: View {
    var body: some View {
        VStack {
            ProgressView()
                .scaleEffect(1.5)
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
            Text("Loading...")
                .foregroundColor(.white)
                .padding(.top, 16)
        }
    }
}

#Preview {
    LoadingView()
        .background(Color.black)
} 