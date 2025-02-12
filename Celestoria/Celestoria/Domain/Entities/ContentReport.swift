//
//  Report.swift
//  Celestoria
//
//  Created by Minjun Kim on 2/4/25.
//

import Foundation

struct ContentReport: Identifiable, Codable, Hashable {
    let id: UUID
    let reporterId: UUID
    let memoryId: UUID
    let createdAt: Date
    
    static func == (lhs: ContentReport, rhs: ContentReport) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case reporterId = "reporter_id"
        case memoryId = "memory_id"
        case createdAt = "created_at"
    }
}
