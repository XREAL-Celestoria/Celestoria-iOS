//
//  CommentSectionView.swift
//  Celestoria
//
//  Created by Minjun Kim on 8/13/25.
//


//
//  CommentSectionView.swift
//  Celestoria
//
//  Created by AI Assistant on 8/12/25.
//

import SwiftUI
import os

struct CommentSectionView: View {
    @ObservedObject var viewModel: MemoryDetailViewModel
    @EnvironmentObject var appState: AppState
    @State private var showAllComments = false
    @FocusState private var isCommentFieldFocused: Bool
    
    private let maxVisibleComments = 3
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Comments header
            HStack {
                Text("Comments")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Colors.NebulaWhite)
                
                if viewModel.comments.count > 0 {
                    Text("(\(viewModel.comments.count))")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Colors.NebulaWhite.opacity(0.7))
                }
                
                Spacer()
                
                if viewModel.comments.count > maxVisibleComments && !showAllComments {
                    Button(action: { showAllComments = true }) {
                        Text("Show all")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Colors.StarfieldPurple)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            
            // Comments list
            if viewModel.isLoadingComments {
                HStack {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .frame(height: 60)
                    Spacer()
                }
            } else if viewModel.comments.isEmpty {
                Text("Be the first to comment")
                    .font(.system(size: 14))
                    .foregroundColor(Colors.NebulaWhite.opacity(0.5))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        let visibleComments = showAllComments ? viewModel.comments : 
                            Array(viewModel.comments.prefix(maxVisibleComments))
                        
                        ForEach(visibleComments, id: \.comment.id) { item in
                            CommentItemView(
                                comment: item.comment,
                                userProfile: item.userProfile,
                                currentUserId: appState.userId,
                                isEditing: viewModel.editingCommentId == item.comment.id,
                                editingText: viewModel.editingCommentText,
                                onEdit: { viewModel.startEditingComment(item.comment.id, currentText: item.comment.content) },
                                onSaveEdit: { Task { await viewModel.saveEditedComment() } },
                                onCancelEdit: { viewModel.cancelEditingComment() },
                                onDelete: { Task { await viewModel.deleteComment(item.comment.id) } },
                                onEditingTextChange: { newText in viewModel.editingCommentText = newText }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .frame(maxHeight: showAllComments ? 300 : nil)
            }
            
            // Comment input
            HStack(spacing: 12) {
                // Profile image
                if let currentUserId = appState.userId {
                    AsyncProfileImage(userId: currentUserId, size: 36)
                        .padding(.leading, 20)
                }
                
                // Text field
                HStack {
                    TextField("Add a comment...", text: $viewModel.commentText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .font(.system(size: 14))
                        .foregroundColor(Colors.NebulaWhite)
                        .focused($isCommentFieldFocused)
                        .disabled(viewModel.isPostingComment)
                        .onSubmit {
                            Task { await viewModel.addComment() }
                        }
                    
                    // Send button
                    Button(action: {
                        Task { await viewModel.addComment() }
                    }) {
                        if viewModel.isPostingComment {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .frame(width: 20, height: 20)
                        } else {
                            Image(systemName: "paperplane.fill")
                                .foregroundColor(viewModel.commentText.isEmpty ? 
                                    Colors.NebulaWhite.opacity(0.3) : Colors.StarfieldPurple)
                                .font(.system(size: 16))
                        }
                    }
                    .disabled(viewModel.commentText.isEmpty || viewModel.isPostingComment)
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Colors.NebulaBlack.opacity(0.3))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Colors.NebulaWhite.opacity(0.2), lineWidth: 1)
                        )
                )
                .padding(.trailing, 20)
            }
            .padding(.bottom, 16)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Colors.NebulaBlack.opacity(0.2))
        )
    }
}

// Removed CommentItemView - now in separate file

// Profile image view helper
public struct ProfileImageView: View {
    let profile: UserProfile
    let size: CGFloat
    
    public var body: some View {
        if let key = profile.profileKey,
           let predefined = PredefinedProfileImage.fromKey(key) {
            Image(predefined.rawValue)
                .resizable()
                .scaledToFill()
                .frame(width: size, height: size)
                .clipShape(Circle())
        } else if let urlString = profile.profileImageURL,
                  let url = URL(string: urlString) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(width: size, height: size)
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: size, height: size)
                        .clipShape(Circle())
                case .failure(_):
                    Image("CardUserProfileImage")
                        .resizable()
                        .scaledToFill()
                        .frame(width: size, height: size)
                        .clipShape(Circle())
                @unknown default:
                    EmptyView()
                }
            }
        } else {
            Image("CardUserProfileImage")
                .resizable()
                .scaledToFill()
                .frame(width: size, height: size)
                .clipShape(Circle())
        }
    }
}

// Removed AsyncProfileImage - now in CommentItemView.swift

extension RelativeDateTimeFormatter {
    static let shared: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter
    }()
}