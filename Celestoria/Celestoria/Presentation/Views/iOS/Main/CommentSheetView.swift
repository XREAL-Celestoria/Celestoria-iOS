//
//  CommentSheetView.swift
//  Celestoria
//
//  Created by Seyoung Park on 8/7/25.
//

import SwiftUI

struct CommentSheetView: View {
    let memory: Memory
    let diContainer: DIContainer
    @StateObject private var viewModel: CommentSheetViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var commentToDelete: Comment? = nil
    
    init(memory: Memory, diContainer: DIContainer) {
        self.memory = memory
        self.diContainer = diContainer
        self._viewModel = StateObject(wrappedValue: CommentSheetViewModel(
            memory: memory,
            diContainer: diContainer
        ))
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack(spacing: 0) {
                    Spacer().frame(height: 16)
                    // Header with drag handle
                    HStack(alignment: .center) {
                        Spacer()
                        RoundedRectangle(cornerRadius: 2.5)
                            .fill(Colors.NebulaWhite.opacity(0.3))
                            .frame(width: 36, height: 5)
                        Spacer()
                    }
                    
                    HStack {
                        Text("Comments")
                            .fontStyle(Fonts.callout)
                            .foregroundColor(Colors.NebulaWhite)
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 30)
                    
                    Spacer().frame(height: 30)
                    
                    // Comments list
                    if viewModel.isLoadingComments {
                        Spacer()
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Colors.NebulaWhite))
                        Spacer()
                    } else if viewModel.comments.isEmpty {
                        Spacer()
                        VStack(spacing: 16) {
                            Image("CommentIcon")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 48, height: 48)
                            
                            Text("No comments yet")
                                .fontStyle(Fonts.subheadline)
                                .foregroundColor(Colors.NebulaWhite)
                            
                            Text("Be the first to comment!")
                                .fontStyle(Fonts.caption1)
                                .foregroundColor(Colors.Placeholder)
                        }
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 32) {
                                ForEach(viewModel.comments, id: \.comment.id) { commentData in
                                    CommentRowView(
                                        comment: commentData.comment,
                                        userProfile: commentData.userProfile,
                                        isOwner: commentData.comment.userId == diContainer.appState.userId,
                                        onRequestDelete: {
                                            commentToDelete = commentData.comment
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.bottom, 20)
                        }
                    }
                    
                    // Input bar
                    ZStack {
                        RoundedRectangle(cornerRadius: 30)
                            .fill(LinearGradient.MainGradient)
                            .frame(height: 60)
                        
                        HStack {
                            Spacer().frame(width: 8)
                            
                            HStack {
                                TextField("Add a comment", text: $viewModel.commentText, axis: .vertical)
                                    .font(.system(.footnote))
                                    .foregroundColor(Colors.NebulaWhite)
                                    .lineLimit(1...3)
                                    .textFieldStyle(PlainTextFieldStyle())
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 24)
                                            .fill(Colors.BackgroundBlack)
                                            .frame(height: 48)
                                    )
                            }
                            
                            Button(action: { Task { await viewModel.postComment() } }) {
                                Image("commentPostIcon")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 20, height: 20)
                            }
                            .disabled(!viewModel.canPost || viewModel.isPosting)
                            
                            Spacer().frame(width: 12)
                        }
                    }
                    .padding(.bottom, 24)
                    .padding(.horizontal, 20)
                }
                .background(Colors.BackgroundBlack)
                .navigationBarHidden(true)
                
                // Fullscreen overlay popup for delete confirmation
                if let commentToDelete = commentToDelete {
                    iOSConfirmationPopupView(
                        title: "Delete Comment",
                        message: "Are you sure you want to delete this comment?",
                        style: .twoButtons(cancelTitle: "Cancel", confirmTitle: "Delete", isDestructive: true),
                        onCancel: { 
                            withAnimation(.easeInOut(duration: 0.4)) {
                                self.commentToDelete = nil
                            }
                        },
                        onConfirm: {
                            Task { await viewModel.deleteComment(commentToDelete.id) }
                            withAnimation(.easeInOut(duration: 0.4)) {
                                self.commentToDelete = nil
                            }
                        }
                    )
                }
            }
        }
        .onAppear {
            Task {
                await viewModel.loadComments()
                await viewModel.loadCurrentUserProfile()
            }
        }
    }
}

// MARK: - Comment Row View
struct CommentRowView: View {
    let comment: Comment
    let userProfile: UserProfile?
    let isOwner: Bool
    let onRequestDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 10) {
                // Profile image
                if let profile = userProfile {
                    ProfileImageView(profile: profile, size: 32)
                } else {
                    Image("profile_gray")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 32, height: 32)
                        .clipShape(Circle())
                }
                
                Text(userProfile?.name ?? "Unknown User")
                    .fontStyle(Fonts.title3)
                    .foregroundStyle(Colors.NebulaWhite)
                
                Text("•")
                    .fontStyle(Fonts.callout)
                    .foregroundStyle(Colors.NebulaWhite)
                
                Text(formatTimeAgo(comment.createdAt))
                    .fontStyle(Fonts.callout)
                    .foregroundStyle(Colors.Placeholder)
                
                Spacer()
                
                if isOwner {
                    Button(action: { onRequestDelete() }) {
                        Image("commentOptionIcon")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                    }
                }
            }
            
            Text(comment.content)
                .fontStyle(Fonts.body1)
                .foregroundStyle(Colors.NebulaWhite)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    private func formatTimeAgo(_ date: Date) -> String {
        let now = Date()
        let timeInterval = now.timeIntervalSince(date)
        if timeInterval < 60 { return "now" }
        if timeInterval < 3600 { return "\(Int(timeInterval / 60))m" }
        if timeInterval < 86400 { return "\(Int(timeInterval / 3600))h" }
        return "\(Int(timeInterval / 86400))d"
    }
}
