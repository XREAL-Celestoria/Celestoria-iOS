//
//  Notification.swift
//  Celestoria
//
//  Created by Minjun Kim on 8/13/25.
//


//
//  Notification.swift
//  Celestoria
//
//  Created by AI Assistant on 8/12/25.
//

import Foundation

struct Notification: Identifiable, Codable, Hashable {
    let id: UUID
    let userId: UUID       // Recipient of the notification
    let actorId: UUID      // User who triggered the notification
    let memoryId: UUID     // Related memory
    let type: NotificationType
    let content: String?   // For comment notifications, contains the comment text
    var isRead: Bool
    let createdAt: Date
    
    enum NotificationType: String, Codable {
        case like = "like"
        case comment = "comment"
    }
    
    static func == (lhs: Notification, rhs: Notification) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case actorId = "actor_id"
        case memoryId = "memory_id"
        case type
        case content
        case isRead = "is_read"
        case createdAt = "created_at"
    }
}

// Extension for creating a new notification
extension Notification {
    init(userId: UUID, actorId: UUID, memoryId: UUID, type: NotificationType, content: String? = nil) {
        self.id = UUID()
        self.userId = userId
        self.actorId = actorId
        self.memoryId = memoryId
        self.type = type
        self.content = content
        self.isRead = false
        self.createdAt = Date()
    }
}