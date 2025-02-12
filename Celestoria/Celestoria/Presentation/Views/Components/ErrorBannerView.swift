//
//  ErrorBannerView.swift
//  Celestoria
//
//  Created by Park Seyoung on 1/20/25.
//

import SwiftUI

struct ErrorBannerView: View {
    let message: String
    let dismissAction: () -> Void

    var body: some View {
        VStack {
            HStack {
                Text(message)
                    .font(.headline)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)

                Spacer()

                Button(action: dismissAction) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white)
                        .imageScale(.large)
                }
            }
            .padding()
            .background(Color.red.opacity(0.9))
            .cornerRadius(10)
            .shadow(radius: 5)
            .padding(.horizontal, 20)
        }
        .transition(.move(edge: .top)) 
        .animation(.easeInOut, value: message)
    }
}
