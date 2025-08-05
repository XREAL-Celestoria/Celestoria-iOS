//
//  UserInfoModalExpandedContent.swift
//  Celestoria
//
//  Created by Seyoung Park on 8/2/25.
//

import SwiftUI

// MARK: - Expanded Content
struct UserInfoModalExpandedContent: View {
    @ObservedObject var viewModel: UserInfoModalViewModel
    let profile: UserProfile
    
    var body: some View {
        VStack(spacing: 20) {
            // Profile section with edit button
            HStack {
                // Large profile image
                ProfileImageView(profile: profile, size: 60)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        AnimatedProfileName(profileName: profile.name)
                        
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
                            Text("\(viewModel.memoryCount)")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        
                        HStack(spacing: 4) {
                            Image("CommentIcon")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 16, height: 16)
                            Text("\(viewModel.commentCount)")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        
                        HStack(spacing: 4) {
                            Image("Like-on")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 16, height: 16)
                            Text("\(viewModel.likeCount)")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                }
                
                Spacer()
            }
            
            // Sort section
            SortSectionView(viewModel: viewModel)
            
            // Memory list using viewModel data
            ForEach(viewModel.mockMemories) { mockMemory in
                MemoryListItemView(mockMemory: mockMemory)
            }
            
            Spacer(minLength: 100)
        }
        .padding(.horizontal, 16)
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }
} 