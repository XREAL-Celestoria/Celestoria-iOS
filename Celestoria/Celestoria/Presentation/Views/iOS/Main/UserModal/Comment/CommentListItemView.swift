//
//  CommentListItemView.swift
//  Celestoria
//
//  Created by Seyoung Park on 8/7/25.
//

import SwiftUI

// MARK: - Comment List Item View
struct CommentListItemView: View {
    let comment: Comment
    let userProfile: UserProfile?
    let onMemoryTap: () -> Void
    
    var body: some View {
        // Comment header
        HStack(alignment: .top, spacing: 16) {
            // User profile image
            if let profile = userProfile {
                ProfileImageView(profile: profile, size: 32)
            } else {
                Image("profile_gray")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())
            }
            
            // User name and comment info
            VStack(alignment: .leading, spacing : 4) {
                HStack(alignment: .center, spacing: 10) {
                    Text(userProfile?.name ?? "Unknown User")
                        .fontStyle(Fonts.subheadline)
                        .foregroundColor(Colors.NebulaWhite)
                    
                    Text("•")
                        .fontStyle(Fonts.callout)
                        .foregroundColor(Colors.NebulaWhite)
                    
                    Text(formatDate(comment.createdAt))
                        .fontStyle(Fonts.callout)
                        .foregroundColor(Colors.Placeholder)
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Text("Left a comment on your memory.")
                    .fontStyle(Fonts.caption2)
                    .foregroundColor(Colors.Placeholder)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // Comment content
                Text(comment.content)
                    .fontStyle(Fonts.footnote)
                    .foregroundColor(Colors.NebulaWhite)
                    .lineLimit(nil)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onTapGesture {
            onMemoryTap()
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let now = Date()
        let timeInterval = now.timeIntervalSince(date)
        if timeInterval < 60 { return "now" }
        if timeInterval < 3600 { return "\(Int(timeInterval / 60))m" }
        if timeInterval < 86400 { return "\(Int(timeInterval / 3600))h" }
        return "\(Int(timeInterval / 86400))d"
    }
}
