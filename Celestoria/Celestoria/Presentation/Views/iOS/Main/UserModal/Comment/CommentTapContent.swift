//
//  CommentTapContent.swift
//  Celestoria-iOS
//
//  Created by Seyoung Park on 8/7/25.
//

import SwiftUI

// MARK: - Comments Tab Content
struct CommentsTabContentView: View {
    @ObservedObject var viewModel: UserInfoModalViewModel
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image("CommentIcon")
                .resizable()
                .scaledToFit()
                .frame(width: 48, height: 48)
            
            Text("No comments yet")
                .fontStyle(Fonts.subheadline)
                .foregroundColor(Colors.NebulaWhite)
            
            Text("This user hasn't received any comments yet.")
                .fontStyle(Fonts.caption1)
                .foregroundColor(Colors.Placeholder)
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
    
    private var commentsListView: some View {
        ScrollView {
            LazyVStack(spacing: 32) {
                ForEach(viewModel.comments.indices, id: \.self) { index in
                    let item = viewModel.comments[index]
                    CommentListItemView(
                        comment: item.0,
                        userProfile: item.1,
                        onMemoryTap: {
                            handleMemoryTap(for: item.0)
                        }
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 32)
        }
        .scrollBounceBehavior(.basedOnSize)
        .scrollIndicators(.hidden)
        .frame(maxWidth: .infinity)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if viewModel.comments.isEmpty {
                emptyStateView
            } else {
                commentsListView
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func handleMemoryTap(for comment: Comment) {
        if let memory = viewModel.memories.first(where: { $0.id == comment.memoryId }) {
            viewModel.selectMemory(memory)
        }
    }
}
