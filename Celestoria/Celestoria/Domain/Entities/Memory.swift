//
//  Memory.swift
//  Celestoria
//
//  Created by Park Seyoung on 1/20/25.
//

import Foundation

struct Memory: Identifiable, Codable, Hashable {
    let id: UUID
    let userId: UUID
    let category: Category
    let title: String
    let note: String
    let createdAt: Date
    let position: Position
    let videoURL: String?
    let thumbnailURL: String?
    let spatialMetadata: SpatialMetadata?
    let isHidden: Bool      // DB에 저장된 값

    struct Position: Codable, Hashable {
        let x: Double
        let y: Double
        let z: Double
    }

    struct SpatialMetadata: Codable, Hashable {
        let projectionKind: String
        let hasLeftStereoEyeView: Bool
        let hasRightStereoEyeView: Bool
        let stereoCameraBaseline: Int
        let spatialQuality: Int
        let horizontalFieldOfView: Int
    }

    static func == (lhs: Memory, rhs: Memory) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case category
        case title
        case note
        case createdAt = "created_at"
        case position
        case videoURL = "video_url"
        case thumbnailURL = "thumbnail_url"
        case spatialMetadata = "spatial_metadata"
        case isHidden = "is_hidden"
    }
}
