//
//  NotificationViewModel.swift
//  Celestoria
//
//  Created by Minjun Kim on 8/13/25.
//


//
//  NotificationViewModel.swift
//  Celestoria
//
//  Created by AI Assistant on 8/12/25.
//

import Foundation
import Combine
import os

// MARK: - Activity Item
enum ActivityItem: Identifiable {
    case comment(Comment, UserProfile?)
    case like(UserProfile?, Date, UUID) // UserProfile?, likedAt, memoryId
    
    var id: String {
        switch self {
        case .comment(let comment, _):
            return "comment_\(comment.id)"
        case .like(_, _, let memoryId):
            return "like_\(memoryId)_\(UUID().uuidString)"
        }
    }
}

@MainActor
final class NotificationViewModel: ObservableObject {
    private let notificationUseCase: NotificationUseCase
    private let appState: AppState
    let diContainer: DIContainer
    private let logger = Logger(subsystem: "com.celestoria", category: "NotificationViewModel")
    private var cancellables = Set<AnyCancellable>()
    
    @Published var notifications: [NotificationWithDetails] = []
    @Published var comments: [(Comment, UserProfile?)] = []
    @Published var likes: [(UserProfile?, Date, UUID)] = [] // Added memoryId
    @Published var combinedActivities: [ActivityItem] = []
    @Published var unreadCount: Int = 0
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var selectedMemoryId: UUID?
    
    init(notificationUseCase: NotificationUseCase, appState: AppState, diContainer: DIContainer) {
        self.notificationUseCase = notificationUseCase
        self.appState = appState
        self.diContainer = diContainer
        
        setupCommentNotifications()
        
        Task {
            await loadNotifications()
        }
    }
    
    deinit {
        cancellables.removeAll()
    }
    
    // Load all notifications
    func loadNotifications() async {
        guard let userId = appState.userId else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        async let notificationsTask = loadNotificationData(userId: userId)
        async let commentsAndLikesTask = loadCommentsAndLikes(userId: userId)
        
        await notificationsTask
        await commentsAndLikesTask
        
        logger.info("Loaded \(self.notifications.count) notifications, \(self.comments.count) comments, \(self.likes.count) likes")
    }
    
    // Load notification data
    private func loadNotificationData(userId: UUID) async {
        do {
            let notificationsWithDetails = try await notificationUseCase.fetchNotificationsWithDetails(for: userId)
            self.notifications = notificationsWithDetails
            
            // Update unread count
            self.unreadCount = self.notifications.filter { !$0.notification.isRead }.count
        } catch {
            logger.error("Failed to load notifications: \(error.localizedDescription)")
            errorMessage = "Failed to load notifications"
        }
    }
    
    // Load comments and likes
    private func loadCommentsAndLikes(userId: UUID) async {
        do {
            // Load user's memories
            let memories = try await diContainer.memoryUseCase.execute(for: userId)
            
            var allComments: [(Comment, UserProfile?)] = []
            var allLikes: [(UserProfile?, Date, UUID)] = [] // Changed to (UserProfile?, Date, UUID)
            var allActivities: [ActivityItem] = []
            
            for memory in memories {
                // Load comments
                let commentsWithProfiles = try await diContainer.commentUseCase.fetchCommentsWithProfiles(for: memory.id)
                allComments.append(contentsOf: commentsWithProfiles)
                
                // Load likes
                let likes = try await diContainer.memoryRepository.fetchLikes(for: memory.id)
                for like in likes {
                    if like.userId != userId { // 자기 자신이 아닌 경우만
                        let profile = try? await diContainer.profileUseCase.fetchProfileByUserId(userId: like.userId)
                        allLikes.append((profile, like.createdAt, memory.id)) // Added memory.id
                    }
                }
            }
            
            // Sort by creation time (newest first)
            allComments.sort { $0.0.createdAt > $1.0.createdAt }
            allLikes.sort { $0.1 > $1.1 }
            
            // Create combined activities
            for commentData in allComments {
                allActivities.append(.comment(commentData.0, commentData.1))
            }
            
            for likeData in allLikes {
                allActivities.append(.like(likeData.0, likeData.1, likeData.2))
            }
            
            // Sort all activities by time (newest first)
            allActivities.sort { activity1, activity2 in
                let date1: Date
                let date2: Date
                
                switch activity1 {
                case .comment(let comment, _):
                    date1 = comment.createdAt
                case .like(_, let date, _):
                    date1 = date
                }
                
                switch activity2 {
                case .comment(let comment, _):
                    date2 = comment.createdAt
                case .like(_, let date, _):
                    date2 = date
                }
                
                return date1 > date2
            }
            
            self.comments = allComments
            self.likes = allLikes
            self.combinedActivities = allActivities
            
        } catch {
            logger.error("Failed to load comments and likes: \(error.localizedDescription)")
        }
    }
    
    // Mark a notification as read
    func markAsRead(_ notificationId: UUID) async {
        do {
            try await notificationUseCase.markAsRead(notificationId: notificationId)
            
            // Update local state
            if let index = self.notifications.firstIndex(where: { $0.notification.id == notificationId }) {
                var updatedNotification = self.notifications[index].notification
                updatedNotification.isRead = true
                self.notifications[index] = NotificationWithDetails(
                    notification: updatedNotification,
                    actorProfile: self.notifications[index].actorProfile,
                    memory: self.notifications[index].memory
                )
            }
            
            // Update unread count
            self.unreadCount = self.notifications.filter { !$0.notification.isRead }.count
            
            logger.info("Marked notification as read: \(notificationId)")
        } catch {
            logger.error("Failed to mark notification as read: \(error.localizedDescription)")
        }
    }
    
    // Mark all notifications as read
    func markAllAsRead() async {
        guard let userId = appState.userId else { return }
        
        do {
            try await notificationUseCase.markAllAsRead(for: userId)
            
            // Update local state
            for index in self.notifications.indices {
                var updatedNotification = self.notifications[index].notification
                updatedNotification.isRead = true
                self.notifications[index] = NotificationWithDetails(
                    notification: updatedNotification,
                    actorProfile: self.notifications[index].actorProfile,
                    memory: self.notifications[index].memory
                )
            }
            
            // Update unread count
            self.unreadCount = 0
            
            logger.info("Marked all notifications as read")
        } catch {
            logger.error("Failed to mark all notifications as read: \(error.localizedDescription)")
        }
    }
    
    // Delete a notification
    func deleteNotification(_ notificationId: UUID) async {
        do {
            try await notificationUseCase.deleteNotification(notificationId: notificationId)
            
            // Remove from local state
            self.notifications.removeAll { $0.notification.id == notificationId }
            
            // Update unread count
            self.unreadCount = self.notifications.filter { !$0.notification.isRead }.count
            
            logger.info("Deleted notification: \(notificationId)")
        } catch {
            logger.error("Failed to delete notification: \(error.localizedDescription)")
        }
    }
    
    // Delete all notifications
    func deleteAllNotifications() async {
        guard let userId = appState.userId else { return }
        
        do {
            try await notificationUseCase.deleteAllNotifications(for: userId)
            
            // Clear local state
            self.notifications = []
            self.unreadCount = 0
            
            logger.info("Deleted all notifications")
        } catch {
            logger.error("Failed to delete all notifications: \(error.localizedDescription)")
        }
    }
    
    // Select a memory to view its details
    func selectMemory(_ memoryId: UUID) {
        selectedMemoryId = memoryId
    }
    
    // Get memory from comment
    func getMemoryFromComment(_ comment: Comment) async -> Memory? {
        do {
            logger.log(level: .info, "Attempting to fetch memory for comment: \(comment.id), memoryId: \(comment.memoryId)")
            let memory = try await diContainer.memoryRepository.fetchMemory(id: comment.memoryId)
            logger.log(level: .info, "Successfully fetched memory")
            return memory
        } catch {
            logger.error("Failed to fetch memory from comment: \(error.localizedDescription)")
            return nil
        }
    }
    
    // Get memory from like (we need to store memoryId in likes)
    func getMemoryFromLike(_ likeData: (UserProfile?, Date, UUID)) async -> Memory? {
        do {
            return try await diContainer.memoryRepository.fetchMemory(id: likeData.2) // memoryId is at index 2
        } catch {
            logger.error("Failed to fetch memory from like: \(error.localizedDescription)")
            return nil
        }
    }
    
    // Refresh notifications
    func refresh() async {
        await loadNotifications()
    }
    
    // MARK: - Comment Notification Handling
    private func setupCommentNotifications() {
        // Comment notifications
        NotificationCenter.default.publisher(for: .commentAdded)
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.loadCommentsAndLikes(userId: self?.appState.userId ?? UUID())
                }
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: .commentUpdated)
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.loadCommentsAndLikes(userId: self?.appState.userId ?? UUID())
                }
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: .commentDeleted)
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.loadCommentsAndLikes(userId: self?.appState.userId ?? UUID())
                }
            }
            .store(in: &cancellables)
        
        // Like notifications
        NotificationCenter.default.publisher(for: .likeAdded)
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.loadCommentsAndLikes(userId: self?.appState.userId ?? UUID())
                }
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: .likeRemoved)
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.loadCommentsAndLikes(userId: self?.appState.userId ?? UUID())
                }
            }
            .store(in: &cancellables)
    }
    
    private func refreshNotificationsForMemory(_ memoryId: UUID) async {
        // Refresh notifications to get the latest state
        await loadNotifications()
        logger.log(level: .info, "Refreshed notifications after comment change for memory: \(memoryId)")
    }
}