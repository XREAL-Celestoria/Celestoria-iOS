//
//  UserProfile.swift
//  Celestoria
//
//  Created by Park Seyoung on 1/20/25.
//

import Foundation

struct UserProfile: Identifiable, Codable, Hashable {
    let id: UUID
    let userId: UUID
    let name: String
    let profileImageURL: String?
    let spaceThumbnailURL: String?
    
    static func == (lhs: UserProfile, rhs: UserProfile) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case name
        case profileImageURL = "profile_image_url"
        case spaceThumbnailURL = "space_thumbnail_url"
    }
}
