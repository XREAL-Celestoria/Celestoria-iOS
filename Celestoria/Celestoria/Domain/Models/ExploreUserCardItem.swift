//
//  GalaxyItem.swift
//  Celestoria
//
//  Created by Park Seyoung on 1/26/25.
//

import Foundation

struct ExploreUserCardItem: Identifiable, Codable, Hashable {
    let id = UUID()
    let userName: String
    let userProfileImageName: String
    let memoryStars: Int
    // let constellations: Int
    let imageName: String
}
