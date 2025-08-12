//
//  Comment.swift
//  Celestoria
//
//  Created by Minjun Kim on 8/13/25.
//


//
//  Comment.swift
//  Celestoria
//
//  Created by AI Assistant on 8/12/25.
//

import Foundation

struct Comment: Identifiable, Codable, Hashable {
    let id: UUID
    let userId: UUID
    let memoryId: UUID
    let content: String
    let createdAt: Date
    let updatedAt: Date
    
    static func == (lhs: Comment, rhs: Comment) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case memoryId = "memory_id"
        case content
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// Extension for creating a new comment
extension Comment {
    init(userId: UUID, memoryId: UUID, content: String) {
        self.id = UUID()
        self.userId = userId
        self.memoryId = memoryId
        self.content = content
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}