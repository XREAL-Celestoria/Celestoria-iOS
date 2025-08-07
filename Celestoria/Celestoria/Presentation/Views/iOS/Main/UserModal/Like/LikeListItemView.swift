//
//  LikeListItemView.swift
//  Celestoria-iOS
//
//  Created by Seyoung Park on 8/7/25.
//

import SwiftUI

// MARK: - Like List Item View
struct LikeListItemView: View {
    let index: Int
    
    var body: some View {
        HStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.1))
                .frame(width: 80, height: 60)
                .overlay(
                    Image(systemName: "heart.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white.opacity(0.3))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Liked Memory \(index + 1)")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                
                Text("Liked \(Int.random(in: 1...30)) days ago")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
    }
}
