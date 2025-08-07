//
//  CommentListItemView.swift
//  Celestoria-iOS
//
//  Created by Seyoung Park on 8/7/25.
//

import SwiftUI

// MARK: - Comment List Item View
struct CommentListItemView: View {
    let index: Int
    
    var body: some View {
        HStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.1))
                .frame(width: 80, height: 60)
                .overlay(
                    Image(systemName: "text.bubble")
                        .font(.system(size: 20))
                        .foregroundColor(.white.opacity(0.3))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Comment \(index + 1)")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                
                Text("This is a sample comment content...")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.6))
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
    }
}
