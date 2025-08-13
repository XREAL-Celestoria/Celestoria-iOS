//
//  LikeListItemView.swift
//  Celestoria-iOS
//
//  Created by Seyoung Park on 8/7/25.
//

import SwiftUI

// MARK: - Like List Item View
struct LikeListItemView: View {
    let userProfile: UserProfile?
    let likedAt: Date
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            if let profile = userProfile {
                ProfileImageView(profile: profile, size: 32)
            } else {
                Image("profile_gray")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())
            }

            
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .center, spacing: 10) {
                    Text(userProfile?.name ?? "Unknown User")
                        .fontStyle(Fonts.subheadline)
                        .foregroundColor(Colors.NebulaWhite)
                    
                    Text("•")
                        .fontStyle(Fonts.callout)
                        .foregroundColor(Colors.NebulaWhite)
                    
                    Text(formatDate(likedAt))
                        .fontStyle(Fonts.callout)
                        .foregroundColor(Colors.Placeholder)
                }
                Text("Liked your memory")
                    .fontStyle(Fonts.caption2)
                    .foregroundColor(Colors.Placeholder)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
