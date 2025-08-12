//
//  Like.swift
//  Celestoria
//
//  Created by Minjun Kim on 7/5/25.
//


//
//  Like.swift
//  Celestoria
//
//  Created by AI Assistant on 2/7/25.
//

import Foundation

struct Like: Identifiable, Codable, Hashable {
    let id: UUID
    let userId: UUID      // 좋아요를 누른 사용자 ID
    let memoryId: UUID    // 좋아요를 받은 메모리 ID
    let createdAt: Date
    
    static func == (lhs: Like, rhs: Like) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case memoryId = "memory_id"
        case createdAt = "created_at"
    }
}

// 유저별 총 좋아요 수를 위한 DTO
struct UserLikeCount: Codable {
    let userId: String
    let totalLikes: Int
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case totalLikes = "total_likes"
    }
} 