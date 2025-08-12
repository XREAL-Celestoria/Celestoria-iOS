//
//  NotificationsView.swift
//  Celestoria
//
//  Created by Minjun Kim on 8/13/25.
//


//
//  NotificationsView.swift
//  Celestoria
//
//  Created by AI Assistant on 8/12/25.
//

import SwiftUI
import os

struct NotificationsView: View {
    @StateObject private var viewModel: NotificationViewModel
    @EnvironmentObject var appState: AppState
    @Environment(\.openWindow) private var openWindow
    @State private var showDeleteAllConfirmation = false
    
    init(notificationUseCase: NotificationUseCase, appState: AppState) {
        _viewModel = StateObject(wrappedValue: NotificationViewModel(
            notificationUseCase: notificationUseCase,
            appState: appState
        ))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            // Content
            if viewModel.isLoading {
                loadingView
            } else if viewModel.notifications.isEmpty {
                emptyView
            } else {
                notificationsList
            }
        }
        .background(Colors.NebulaBlack.opacity(0.5))
        .cornerRadius(16)
        .task {
            await viewModel.loadNotifications()
        }
        .alert("Delete All Notifications", isPresented: $showDeleteAllConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete All", role: .destructive) {
                Task {
                    await viewModel.deleteAllNotifications()
                }
            }
        } message: {
            Text("Are you sure you want to delete all notifications? This action cannot be undone.")
        }
    }
    
    private var headerView: some View {
        HStack {
            Text("Notifications")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(Colors.NebulaWhite)
            
            if viewModel.unreadCount > 0 {
                Text("\(viewModel.unreadCount)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Colors.NebulaWhite)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Colors.StarfieldPurple)
                    .cornerRadius(10)
            }
            
            Spacer()
            
            if !viewModel.notifications.isEmpty {
                Menu {
                    Button(action: {
                        Task {
                            await viewModel.markAllAsRead()
                        }
                    }) {
                        Label("Mark All as Read", systemImage: "checkmark.circle")
                    }
                    
                    Button(role: .destructive, action: {
                        showDeleteAllConfirmation = true
                    }) {
                        Label("Delete All", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 18))
                        .foregroundColor(Colors.NebulaWhite.opacity(0.7))
                        .padding(8)
                        .background(Colors.NebulaBlack.opacity(0.3))
                        .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(20)
    }
    
    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(1.5)
            Text("Loading notifications...")
                .font(.system(size: 14))
                .foregroundColor(Colors.NebulaWhite.opacity(0.5))
                .padding(.top, 16)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyView: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "bell.slash")
                .font(.system(size: 48))
                .foregroundColor(Colors.NebulaWhite.opacity(0.3))
            
            Text("No notifications yet")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(Colors.NebulaWhite.opacity(0.5))
            
            Text("You'll see likes and comments on your memories here")
                .font(.system(size: 14))
                .foregroundColor(Colors.NebulaWhite.opacity(0.3))
                .multilineTextAlignment(.center)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }
    
    private var notificationsList: some View {
        ScrollView {
            VStack(spacing: 1) {
                ForEach(viewModel.notifications) { notificationDetail in
                    NotificationItemView(
                        notificationDetail: notificationDetail,
                        onTap: {
                            Task {
                                // Mark as read if not already
                                if !notificationDetail.notification.isRead {
                                    await viewModel.markAsRead(notificationDetail.notification.id)
                                }
                                
                                // Open memory detail
                                if let memory = notificationDetail.memory {
                                    openWindow(value: memory)
                                }
                            }
                        },
                        onDelete: {
                            Task {
                                await viewModel.deleteNotification(notificationDetail.notification.id)
                            }
                        }
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }
}

struct NotificationItemView: View {
    let notificationDetail: NotificationWithDetails
    let onTap: () -> Void
    let onDelete: () -> Void
    
    @State private var isHovering = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Actor profile image
            if let profile = notificationDetail.actorProfile {
                ProfileImageView(profile: profile, size: 44)
            } else {
                Image("CardUserProfileImage")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 44, height: 44)
                    .clipShape(Circle())
            }
            
            VStack(alignment: .leading, spacing: 4) {
                // Notification message
                Text(notificationDetail.message)
                    .font(.system(size: 14, weight: notificationDetail.notification.isRead ? .regular : .semibold))
                    .foregroundColor(Colors.NebulaWhite)
                    .lineLimit(2)
                
                // Time
                Text(notificationDetail.relativeTime)
                    .font(.system(size: 12))
                    .foregroundColor(Colors.NebulaWhite.opacity(0.5))
            }
            
            Spacer()
            
            // Memory thumbnail
            if let memory = notificationDetail.memory,
               let thumbnailURL = memory.thumbnailURL,
               let url = URL(string: thumbnailURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 60, height: 60)
                            .cornerRadius(8)
                    case .empty:
                        ProgressView()
                            .frame(width: 60, height: 60)
                    case .failure(_):
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Colors.NebulaBlack.opacity(0.3))
                            .frame(width: 60, height: 60)
                    @unknown default:
                        EmptyView()
                    }
                }
            }
            
            // Delete button (visible on hover)
            if isHovering {
                Button(action: onDelete) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(Colors.NebulaWhite.opacity(0.5))
                }
                .buttonStyle(PlainButtonStyle())
                .transition(.opacity)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(notificationDetail.notification.isRead ? 
                    Color.clear : Colors.StarfieldPurple.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isHovering ? Colors.StarfieldPurple.opacity(0.3) : Color.clear, lineWidth: 1)
                )
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovering = hovering
            }
        }
        .onTapGesture {
            onTap()
        }
    }
}