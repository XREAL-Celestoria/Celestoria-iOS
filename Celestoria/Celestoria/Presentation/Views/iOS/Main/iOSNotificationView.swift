//
//  iOSNotificationView.swift
//  CelestoriaMobile
//
//  Created by Seyoung Park on 8/12/25.
//

import SwiftUI

// If iOSUndefinedLoadingView is in a separate module, add the import here
// import YourModuleName

extension Foundation.Notification.Name {
	static let openMemoryDetail = Foundation.Notification.Name("OpenMemoryDetail")
}

struct iOSNotificationView: View {
    @StateObject private var viewModel: NotificationViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedMemory: Memory?
    @State private var showMemoryDetail = false
    @State private var showCommentSheet = false
    @State private var showLikeSheet = false
    @State private var presentedMemory: Memory?
    
    init(diContainer: DIContainer) {
        let useCase = diContainer.notificationUseCase
        let appState = diContainer.appState
        let vm = NotificationViewModel(notificationUseCase: useCase, appState: appState, diContainer: diContainer)
        self._viewModel = StateObject(wrappedValue: vm)
    }
    
    var body: some View {
        NavigationView {
            contentView
                .background(Colors.BackgroundBlack)
                .navigationBarHidden(true)
        }
        .fullScreenCover(item: $presentedMemory) { memory in
            iOSMemoryDetailView(
                memory: memory,
                diContainer: viewModel.diContainer
            )
        }
        .sheet(isPresented: $showCommentSheet) {
            if let memory = selectedMemory {
                CommentSheetView(memory: memory, diContainer: viewModel.diContainer)
            }
        }
        .sheet(isPresented: $showLikeSheet) {
            if let memory = selectedMemory {
                LikeSheetView(memory: memory, diContainer: viewModel.diContainer)
            }
        }
    }
    
    // MARK: - Subviews
    
    private var contentView: some View {
        Group {
            if viewModel.isLoading {
                loadingView
            } else if viewModel.combinedActivities.isEmpty {
                emptyStateView
            } else {
                activitiesListView
            }
        }
    }
    
    private var loadingView: some View {
        iOSUnifiedLoadingView(title: "Loading...")
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "bell.slash")
                .font(.system(size: 48))
                .foregroundStyle(LinearGradient.MainGradient)
            Text("No notifications yet")
                .fontStyle(Fonts.subheadline)
                .foregroundColor(Colors.NebulaWhite)
            Text("You'll see notifications here when someone interacts with your memories")
                .fontStyle(Fonts.caption1)
                .foregroundColor(Colors.Placeholder)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
    }
    
    private var activitiesListView: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                let groups = groupedActivities
                ForEach(NotificationTimeGroup.allCases, id: \.self) { (timeGroup: NotificationTimeGroup) in
                    if let items = groups[timeGroup], !items.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(timeGroup.displayName)
                                .fontStyle(Fonts.callout)
                                .foregroundStyle(LinearGradient.SubGradient)
                                .padding(.horizontal, 20)
                                .padding(.top, 16)
                            ForEach(items, id: \.id) { activity in
                                switch activity {
                                case .comment(let comment, let userProfile):
                                    Button(action: { handleCommentTap(comment: comment) }) {
                                        CommentItemView(
                                            comment: comment,
                                            userProfile: userProfile
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 6)
                                case .like(let userProfile, let likedAt, let memoryId):
                                    Button(action: { handleLikeTap(likeData: (userProfile, likedAt, memoryId)) }) {
                                        LikeItemView(
                                            userProfile: userProfile,
                                            likedAt: likedAt
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 6)
                                }
                            }
                        }
                    }
                }
            }
            .padding(.bottom, 12)
        }
    }
    
    // Group combined activities by time
    private var groupedActivities: [NotificationTimeGroup: [ActivityItem]] {
        let now = Date()
        let calendar = Calendar.current
        return Dictionary(grouping: viewModel.combinedActivities) { activity in
            let date: Date
            switch activity {
            case .comment(let comment, _):
                date = comment.createdAt
            case .like(_, let likedAt, _):
                date = likedAt
            }
            let days = calendar.dateComponents([.day], from: date, to: now).day ?? 0
            if days == 0 { return .today }
            if days <= 7 { return .last7Days }
            return .last30Days
        }
    }
    
    // Group comments by time
    private var groupedComments: [NotificationTimeGroup: [(Comment, UserProfile?)]] {
        let now = Date()
        let calendar = Calendar.current
        
        return Dictionary(grouping: viewModel.comments) { commentData in
            let daysDifference = calendar.dateComponents([.day], from: commentData.0.createdAt, to: now).day ?? 0
            if daysDifference == 0 { return .today }
            if daysDifference <= 7 { return .last7Days }
            return .last30Days
        }
    }
    
    // Group likes by time
    private var groupedLikes: [NotificationTimeGroup: [(UserProfile?, Date, UUID)]] {
        let now = Date()
        let calendar = Calendar.current
        
        return Dictionary(grouping: viewModel.likes) { likeData in
            let daysDifference = calendar.dateComponents([.day], from: likeData.1, to: now).day ?? 0
            if daysDifference == 0 { return .today }
            if daysDifference <= 7 { return .last7Days }
            return .last30Days
        }
    }
    
    private func handleCommentTap(comment: Comment) {
        Task {
            if let memory = await viewModel.getMemoryFromComment(comment) {
                await MainActor.run { presentedMemory = memory }
            }
        }
    }
    
    private func handleLikeTap(likeData: (UserProfile?, Date, UUID)) {
        Task {
            if let memory = await viewModel.getMemoryFromLike(likeData) {
                await MainActor.run { presentedMemory = memory }
            }
        }
    }
}

// MARK: - Comment Item View
struct CommentItemView: View {
    let comment: Comment
    let userProfile: UserProfile?
    
    var body: some View {
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
            VStack(alignment: .leading, spacing: 4) {
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

// MARK: - Like Item View
struct LikeItemView: View {
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

// MARK: - Notification Time Group
enum NotificationTimeGroup: Int, CaseIterable {
    case today = 0
    case last7Days = 1
    case last30Days = 2
    
    var displayName: String {
        switch self {
        case .today:
            return "Today"
        case .last7Days:
            return "Last 7 days"
        case .last30Days:
            return "Last 30 days"
        }
    }
}

// MARK: - Notification Row View
struct NotificationRowView: View {
    let notificationData: NotificationWithDetails
    let onMemoryTap: () -> Void
    let onMarkAsRead: () -> Void
    
    var body: some View {
        Button(action: {
            onMarkAsRead()
            onMemoryTap()
        }) {
            HStack(spacing: 16) {
                // Notification icon
                Circle()
                    .fill(notificationIconColor)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: notificationIconName)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                    )
                
                // Notification content
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(notificationData.actorProfile?.name ?? "Unknown User")
                            .fontStyle(Fonts.subheadline)
                            .foregroundColor(Colors.NebulaWhite)
                        
                        Text("•")
                            .fontStyle(Fonts.caption1)
                            .foregroundColor(Colors.NebulaWhite.opacity(0.6))
                        
                        Text(formatTimeAgo(notificationData.notification.createdAt))
                            .fontStyle(Fonts.caption1)
                            .foregroundColor(Colors.NebulaWhite.opacity(0.6))
                    }
                    
                    Text(notificationActionText)
                        .fontStyle(Fonts.caption1)
                        .foregroundColor(Colors.NebulaWhite.opacity(0.8))
                        .multilineTextAlignment(.leading)
                    
                    // Show comment content for comment notifications
                    if notificationData.notification.type == .comment,
                       let commentContent = extractCommentContent(from: notificationData.notification) {
                        Text(commentContent)
                            .fontStyle(Fonts.body2)
                            .foregroundColor(Colors.NebulaWhite)
                            .multilineTextAlignment(.leading)
                            .lineLimit(3)
                    }
                }
                
                Spacer()
                
                // Unread indicator
                if !notificationData.notification.isRead {
                    Circle()
                        .fill(Colors.NebulaWhite)
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Colors.BackgroundBlack.opacity(0.3))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Colors.NebulaWhite.opacity(0.1), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Computed Properties
    private var notificationIconColor: Color {
        switch notificationData.notification.type {
        case .comment:
            return Color(red: 0.275, green: 0.325, blue: 0.439) // Light blue
        case .like:
            return Color(red: 0.290, green: 0.463, blue: 0.624) // Purple
        default:
            return Colors.NebulaWhite.opacity(0.6)
        }
    }
    
    private var notificationIconName: String {
        switch notificationData.notification.type {
        case .comment:
            return "message.circle.fill"
        case .like:
            return "heart.fill"
        default:
            return "bell.fill"
        }
    }
    
    private var notificationActionText: String {
        switch notificationData.notification.type {
        case .comment:
            return "Left a comment on your memory."
        case .like:
            return "Liked your memory."
        default:
            return "Interacted with your memory."
        }
    }
    
    // MARK: - Helper Methods
    private func formatTimeAgo(_ date: Date) -> String {
        let now = Date()
        let timeInterval = now.timeIntervalSince(date)
        
        if timeInterval < 60 {
            return "now"
        } else if timeInterval < 3600 {
            let minutes = Int(timeInterval / 60)
            return "\(minutes)m"
        } else if timeInterval < 86400 {
            let hours = Int(timeInterval / 3600)
            return "\(hours)h"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "dd/MM/yy"
            return formatter.string(from: date)
        }
    }
    
    private func extractCommentContent(from notification: Notification) -> String? {
        // This would need to be implemented based on your notification structure
        // For now, returning nil as placeholder
        return nil
    }
}


