//
//  NotificationRepository.swift
//  Celestoria
//
//  Created by Minjun Kim on 8/13/25.
//


//
//  NotificationRepository.swift
//  Celestoria
//
//  Created by AI Assistant on 8/12/25.
//

import Foundation
import Supabase
import os

class NotificationRepository {
    private let supabase: SupabaseClient
    private let logger = Logger(subsystem: "com.celestoria", category: "NotificationRepository")
    
    init(supabase: SupabaseClient) {
        self.supabase = supabase
    }
    
    // MARK: - Notification CRUD Operations
    
    // Fetch all notifications for a user
    func fetchNotifications(for userId: UUID) async throws -> [Notification] {
        logger.info("Fetching notifications for user: \(userId)")
        
        do {
            let notifications: [Notification] = try await supabase
                .from("notifications")
                .select()
                .eq("user_id", value: userId.uuidString)
                .order("created_at", ascending: false)
                .execute()
                .value
            
            logger.info("Fetched \(notifications.count) notifications")
            return notifications
        } catch {
            logger.error("Failed to fetch notifications: \(error)")
            throw error
        }
    }
    
    // Fetch unread notifications count
    func fetchUnreadCount(for userId: UUID) async throws -> Int {
        let notifications: [Notification] = try await supabase
            .from("notifications")
            .select()
            .eq("user_id", value: userId.uuidString)
            .eq("is_read", value: false)
            .execute()
            .value
        
        return notifications.count
    }
    
    // Mark a notification as read
    func markAsRead(notificationId: UUID) async throws {
        logger.info("Marking notification as read: \(notificationId)")
        
        try await supabase
            .from("notifications")
            .update(["is_read": true])
            .eq("id", value: notificationId.uuidString)
            .execute()
    }
    
    // Mark all notifications as read for a user
    func markAllAsRead(for userId: UUID) async throws {
        logger.info("Marking all notifications as read for user: \(userId)")
        
        try await supabase
            .from("notifications")
            .update(["is_read": true])
            .eq("user_id", value: userId.uuidString)
            .eq("is_read", value: false)
            .execute()
    }
    
    // Delete a notification
    func deleteNotification(notificationId: UUID) async throws {
        logger.info("Deleting notification: \(notificationId)")
        
        try await supabase
            .from("notifications")
            .delete()
            .eq("id", value: notificationId.uuidString)
            .execute()
    }
    
    // Delete all notifications for a user
    func deleteAllNotifications(for userId: UUID) async throws {
        logger.info("Deleting all notifications for user: \(userId)")
        
        try await supabase
            .from("notifications")
            .delete()
            .eq("user_id", value: userId.uuidString)
            .execute()
    }
    
    // Create a notification (for manual creation, automatic creation is handled by database triggers)
    func createNotification(_ notification: Notification) async throws {
        logger.info("Creating notification manually")
        
        do {
            try await supabase
                .from("notifications")
                .insert(notification)
                .execute()
            logger.info("Notification created successfully")
        } catch {
            logger.error("Failed to create notification: \(error)")
            throw error
        }
    }
    
    // MARK: - Notification with User Info
    
    // Fetch notifications with actor user profiles
    func fetchNotificationsWithUserInfo(for userId: UUID) async throws -> [(notification: Notification, actorProfile: UserProfile?, memory: Memory?)] {
        logger.info("Fetching notifications with user info for user: \(userId)")
        
        // First fetch notifications
        let notifications = try await fetchNotifications(for: userId)
        
        var results: [(Notification, UserProfile?, Memory?)] = []
        
        // Fetch user profiles and memories for each notification
        for notification in notifications {
            // Fetch actor profile
            let actorProfiles: [UserProfile] = try await supabase
                .from("user_profiles")
                .select()
                .eq("user_id", value: notification.actorId.uuidString)
                .execute()
                .value
            
            // Fetch memory
            let memories: [Memory] = try await supabase
                .from("memories")
                .select()
                .eq("id", value: notification.memoryId.uuidString)
                .execute()
                .value
            
            results.append((notification, actorProfiles.first, memories.first))
        }
        
        return results
    }
}