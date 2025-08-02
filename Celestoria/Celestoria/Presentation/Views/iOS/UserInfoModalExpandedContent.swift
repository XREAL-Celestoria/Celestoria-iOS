//
//  UserInfoModalExpandedContent.swift
//  Celestoria
//
//  Created by Seyoung Park on 8/2/25.
//

import SwiftUI

// MARK: - Expanded Content
struct UserInfoModalExpandedContent: View {
    let profile: UserProfile
    let memoryCount: Int
    let commentCount: Int
    let likeCount: Int
    
    var body: some View {
        VStack(spacing: 20) {
            // Profile section with edit button
            HStack {
                // Large profile image
                ProfileImageView(profile: profile, size: 60)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(profile.name)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Image(systemName: "pencil")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    // Stats row
                    HStack(spacing: 20) {
                        HStack(spacing: 4) {
                            Image("Memory-icon")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 16, height: 16)
                            Text("\(memoryCount)")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        
                        HStack(spacing: 4) {
                            Image("CommentIcon")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 16, height: 16)
                            Text("\(commentCount)")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        
                        HStack(spacing: 4) {
                            Image("Like-on")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 16, height: 16)
                            Text("\(likeCount)")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                }
                
                Spacer()
            }
            
            // Sort section
            HStack {
                Text("Sort by")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                
                Text("Latest")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: "chevron.down")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.1))
            )
            
            // Placeholder content to fill the screen
            ForEach(0..<10, id: \.self) { index in
                HStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 80, height: 60)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Memory \(index + 1)")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                        
                        Text("\(Int.random(in: 10...100)) views • \(Int.random(in: 1...7)) days ago")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
            }
            
            Spacer(minLength: 100)
        }
        .padding(.horizontal, 16)
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }
} 