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

@MainActor
final class NotificationViewModel: ObservableObject {
    private let notificationUseCase: NotificationUseCase
    private let appState: AppState
    private let logger = Logger(subsystem: "com.celestoria", category: "NotificationViewModel")
    
    @Published var notifications: [NotificationWithDetails] = []
    @Published var unreadCount: Int = 0
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var selectedMemoryId: UUID?
    
    init(notificationUseCase: NotificationUseCase, appState: AppState) {
        self.notificationUseCase = notificationUseCase
        self.appState = appState
        
        Task {
            await loadNotifications()
        }
    }
    
    // Load all notifications
    func loadNotifications() async {
        guard let userId = appState.userId else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let notificationsWithDetails = try await notificationUseCase.fetchNotificationsWithDetails(for: userId)
            self.notifications = notificationsWithDetails
            
            // Update unread count
            self.unreadCount = notifications.filter { !$0.notification.isRead }.count
            
            logger.info("Loaded \(notificationsWithDetails.count) notifications")
        } catch {
            logger.error("Failed to load notifications: \(error.localizedDescription)")
            errorMessage = "Failed to load notifications"
        }
    }
    
    // Mark a notification as read
    func markAsRead(_ notificationId: UUID) async {
        do {
            try await notificationUseCase.markAsRead(notificationId: notificationId)
            
            // Update local state
            if let index = notifications.firstIndex(where: { $0.notification.id == notificationId }) {
                var updatedNotification = notifications[index].notification
                updatedNotification.isRead = true
                notifications[index] = NotificationWithDetails(
                    notification: updatedNotification,
                    actorProfile: notifications[index].actorProfile,
                    memory: notifications[index].memory
                )
            }
            
            // Update unread count
            unreadCount = notifications.filter { !$0.notification.isRead }.count
            
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
            for index in notifications.indices {
                var updatedNotification = notifications[index].notification
                updatedNotification.isRead = true
                notifications[index] = NotificationWithDetails(
                    notification: updatedNotification,
                    actorProfile: notifications[index].actorProfile,
                    memory: notifications[index].memory
                )
            }
            
            unreadCount = 0
            
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
            notifications.removeAll { $0.notification.id == notificationId }
            
            // Update unread count
            unreadCount = notifications.filter { !$0.notification.isRead }.count
            
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
            notifications = []
            unreadCount = 0
            
            logger.info("Deleted all notifications")
        } catch {
            logger.error("Failed to delete all notifications: \(error.localizedDescription)")
        }
    }
    
    // Select a memory to view its details
    func selectMemory(_ memoryId: UUID) {
        selectedMemoryId = memoryId
    }
    
    // Refresh notifications
    func refresh() async {
        await loadNotifications()
    }
}