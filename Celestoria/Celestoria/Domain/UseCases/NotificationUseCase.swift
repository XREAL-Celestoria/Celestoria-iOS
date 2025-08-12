//
//  NotificationUseCase.swift
//  Celestoria
//
//  Created by Minjun Kim on 8/13/25.
//


//
//  NotificationUseCase.swift
//  Celestoria
//
//  Created by AI Assistant on 8/12/25.
//

import Foundation
import os

// Use case for managing notifications
class NotificationUseCase {
    private let notificationRepository: NotificationRepository
    private let profileUseCase: ProfileUseCase
    private let memoryRepository: MemoryRepository
    private let logger = Logger(subsystem: "com.celestoria", category: "NotificationUseCase")
    
    init(notificationRepository: NotificationRepository, 
         profileUseCase: ProfileUseCase,
         memoryRepository: MemoryRepository) {
        self.notificationRepository = notificationRepository
        self.profileUseCase = profileUseCase
        self.memoryRepository = memoryRepository
    }
    
    // Fetch all notifications for a user
    func fetchNotifications(for userId: UUID) async throws -> [Notification] {
        return try await notificationRepository.fetchNotifications(for: userId)
    }
    
    // Fetch notifications with actor profiles and memory info
    func fetchNotificationsWithDetails(for userId: UUID) async throws -> [NotificationWithDetails] {
        let notificationsWithInfo = try await notificationRepository.fetchNotificationsWithUserInfo(for: userId)
        
        var detailedNotifications: [NotificationWithDetails] = []
        
        for (notification, actorProfile, memory) in notificationsWithInfo {
            let details = NotificationWithDetails(
                notification: notification,
                actorProfile: actorProfile,
                memory: memory
            )
            detailedNotifications.append(details)
        }
        
        return detailedNotifications
    }
    
    // Get unread notifications count
    func getUnreadCount(for userId: UUID) async throws -> Int {
        return try await notificationRepository.fetchUnreadCount(for: userId)
    }
    
    // Mark a notification as read
    func markAsRead(notificationId: UUID) async throws {
        try await notificationRepository.markAsRead(notificationId: notificationId)
        logger.info("Notification marked as read: \(notificationId)")
    }
    
    // Mark all notifications as read
    func markAllAsRead(for userId: UUID) async throws {
        try await notificationRepository.markAllAsRead(for: userId)
        logger.info("All notifications marked as read for user: \(userId)")
    }
    
    // Delete a notification
    func deleteNotification(notificationId: UUID) async throws {
        try await notificationRepository.deleteNotification(notificationId: notificationId)
        logger.info("Notification deleted: \(notificationId)")
    }
    
    // Delete all notifications
    func deleteAllNotifications(for userId: UUID) async throws {
        try await notificationRepository.deleteAllNotifications(for: userId)
        logger.info("All notifications deleted for user: \(userId)")
    }
}

// Notification with additional details
struct NotificationWithDetails: Identifiable {
    let notification: Notification
    let actorProfile: UserProfile?
    let memory: Memory?
    
    var id: UUID { notification.id }
    
    // Generate notification message based on type
    var message: String {
        let actorName = actorProfile?.name ?? "Someone"
        
        switch notification.type {
        case .like:
            return "\(actorName) liked your memory"
        case .comment:
            if let content = notification.content {
                let truncatedContent = content.count > 50 ? 
                    String(content.prefix(50)) + "..." : content
                return "\(actorName) commented on your memory: \"\(truncatedContent)\""
            } else {
                return "\(actorName) commented on your memory"
            }
        }
    }
    
    // Get relative time string
    var relativeTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: notification.createdAt, relativeTo: Date())
    }
}