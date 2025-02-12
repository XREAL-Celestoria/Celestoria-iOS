//
//  Block.swift
//  Celestoria
//
//  Created by Minjun Kim on 2/4/25.
//

import Foundation

struct Block: Identifiable, Codable, Hashable {
    let id: UUID
    let reporterId: UUID
    let blockedUserId: UUID
    let createdAt: Date
    
    static func == (lhs: Block, rhs: Block) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case reporterId = "reporter_id"
        case blockedUserId = "blocked_user_id"
        case createdAt = "created_at"
    }
}
