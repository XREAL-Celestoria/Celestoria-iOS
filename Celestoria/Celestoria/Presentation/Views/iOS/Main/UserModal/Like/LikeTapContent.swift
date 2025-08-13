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
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image("Like-on")
                .resizable()
                .scaledToFit()
                .frame(width: 48, height: 48)
            
            Text("No likes yet")
                .fontStyle(Fonts.subheadline)
                .foregroundColor(Colors.NebulaWhite)
            
            Text("This user's memories haven't received any likes yet.")
                .fontStyle(Fonts.caption1)
                .foregroundColor(Colors.Placeholder)
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
    
    private var likedUsersListView: some View {
        ScrollView {
            LazyVStack(spacing: 32) {
                ForEach(viewModel.likedUsers.indices, id: \.self) { index in
                    let item = viewModel.likedUsers[index]
                    Button(action: {
                        if let memory = viewModel.memories.first(where: { $0.id == item.2 }) {
                            viewModel.selectMemory(memory)
                        }
                    }) {
                        LikeListItemView(
                            userProfile: item.0,
                            likedAt: item.1
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 32)
        }
        .scrollBounceBehavior(.basedOnSize)
        .scrollIndicators(.hidden)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if viewModel.likedUsers.isEmpty {
                emptyStateView
            } else {
                likedUsersListView
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
