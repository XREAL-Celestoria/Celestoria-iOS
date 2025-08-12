//
//  CommentItemView.swift
//  Celestoria
//
//  Created by Minjun Kim on 8/13/25.
//


//
//  CommentItemView.swift
//  Celestoria
//
//  Created by AI Assistant on 8/12/25.
//

import SwiftUI

// Individual comment item view
struct CommentItemView: View {
    let comment: Comment
    let userProfile: UserProfile?
    let currentUserId: UUID?
    let isEditing: Bool
    let editingText: String
    let onEdit: () -> Void
    let onSaveEdit: () -> Void
    let onCancelEdit: () -> Void
    let onDelete: () -> Void
    let onEditingTextChange: (String) -> Void
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // User profile image
            if let profile = userProfile {
                if let key = profile.profileKey,
                   let predefined = PredefinedProfileImage.fromKey(key) {
                    Image(predefined.rawValue)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 36, height: 36)
                        .clipShape(Circle())
                } else if let urlString = profile.profileImageURL,
                          let url = URL(string: urlString) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .frame(width: 36, height: 36)
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 36, height: 36)
                                .clipShape(Circle())
                        case .failure(_):
                            Image("CardUserProfileImage")
                                .resizable()
                                .scaledToFill()
                                .frame(width: 36, height: 36)
                                .clipShape(Circle())
                        @unknown default:
                            EmptyView()
                        }
                    }
                } else {
                    Image("CardUserProfileImage")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 36, height: 36)
                        .clipShape(Circle())
                }
            } else {
                Image("CardUserProfileImage")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 36, height: 36)
                    .clipShape(Circle())
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(userProfile?.name ?? "Unknown")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Colors.NebulaWhite)
                    
                    Text(relativeTime(from: comment.createdAt))
                        .font(.system(size: 12))
                        .foregroundColor(Colors.NebulaWhite.opacity(0.6))
                    
                    Spacer()
                    
                    // Action buttons for comment owner
                    if currentUserId == comment.userId {
                        HStack(spacing: 8) {
                            if isEditing {
                                Button(action: onSaveEdit) {
                                    Text("Save")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(Colors.StarfieldPurple)
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                Button(action: onCancelEdit) {
                                    Text("Cancel")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(Colors.NebulaWhite.opacity(0.6))
                                }
                                .buttonStyle(PlainButtonStyle())
                            } else {
                                Button(action: onEdit) {
                                    Image(systemName: "pencil")
                                        .font(.system(size: 14))
                                        .foregroundColor(Colors.NebulaWhite.opacity(0.6))
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                Button(action: onDelete) {
                                    Image(systemName: "trash")
                                        .font(.system(size: 14))
                                        .foregroundColor(Colors.NebulaRed.opacity(0.8))
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                }
                
                if isEditing {
                    TextField("Edit comment...", text: .init(
                        get: { editingText },
                        set: onEditingTextChange
                    ))
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(.system(size: 14))
                    .foregroundColor(Colors.NebulaWhite)
                    .padding(8)
                    .background(Colors.NebulaBlack.opacity(0.5))
                    .cornerRadius(8)
                } else {
                    Text(comment.content)
                        .font(.system(size: 14))
                        .foregroundColor(Colors.NebulaWhite.opacity(0.9))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    private func relativeTime(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// Helper view for async profile image loading
public struct AsyncProfileImage: View {
    let userId: UUID
    let size: CGFloat
    @State private var userProfile: UserProfile?
    @State private var isLoading = true
    @EnvironmentObject private var diContainer: DIContainer
    
    public init(userId: UUID, size: CGFloat = 44) {
        self.userId = userId
        self.size = size
    }
    
    public var body: some View {
        Group {
            if let profile = userProfile {
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
                        case .failure:
                            defaultProfileImage
                        @unknown default:
                            defaultProfileImage
                        }
                    }
                } else {
                    defaultProfileImage
                }
            } else if isLoading {
                ProgressView()
                    .frame(width: size, height: size)
            } else {
                defaultProfileImage
            }
        }
        .onAppear {
            Task {
                await loadProfile()
            }
        }
    }
    
    private var defaultProfileImage: some View {
        Image("CardUserProfileImage")
            .resizable()
            .scaledToFill()
            .frame(width: size, height: size)
            .clipShape(Circle())
    }
    
    private func loadProfile() async {
        do {
            userProfile = try await diContainer.profileUseCase.fetchProfileByUserId(userId: userId)
        } catch {
            print("Failed to load profile for user \(userId): \(error)")
        }
        isLoading = false
    }
}