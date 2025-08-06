//
//  LikeTapContent.swift
//  Celestoria
//
//  Created by Seyoung Park on 8/7/25.
//

import SwiftUI

// MARK: - Likes Tab Content
struct LikesTabContentView: View {
    @ObservedObject var viewModel: UserInfoModalViewModel
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            VStack(spacing: 16) {
                Image("Like-on")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 48, height: 48)
                    .foregroundColor(Colors.NebulaWhite.opacity(0.6))
                
                Text("Coming Soon")
                    .fontStyle(Fonts.title3)
                    .foregroundColor(Colors.NebulaWhite)
                
                Text("Likes feature is currently under development.\nStay tuned for updates!")
                    .fontStyle(Fonts.body2)
                    .foregroundColor(Colors.NebulaWhite.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 32)
    }
}
