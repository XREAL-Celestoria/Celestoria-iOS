//
//  ImageAssetHelper.swift
//  Celestoria
//
//  Created by Assistant on 7/20/25.
//

import SwiftUI

/// Helper class for consistent image asset access across platforms
class ImageAssetHelper {
    
    // MARK: - Thumbnail Images
    
    /// Maps spaceThumbnail names to actual asset names
    static func thumbnailImageName(for id: String?) -> String {
        guard let id = id else { return "Thumbnail1" }
        
        // Handle both formats: "spaceThumbnail01" and "1"
        if id.hasPrefix("spaceThumbnail") {
            let number = id.replacingOccurrences(of: "spaceThumbnail", with: "")
                           .replacingOccurrences(of: "0", with: "")
            return "Thumbnail\(number)"
        } else if let intId = Int(id), intId >= 1 && intId <= 6 {
            return "Thumbnail\(intId)"
        }
        
        return "Thumbnail1" // Default
    }
    
    /// Gets the numeric ID from a thumbnail name
    static func thumbnailId(from name: String) -> String {
        if name.hasPrefix("Thumbnail") {
            return name.replacingOccurrences(of: "Thumbnail", with: "")
        } else if name.hasPrefix("spaceThumbnail") {
            return name.replacingOccurrences(of: "spaceThumbnail0", with: "")
                      .replacingOccurrences(of: "spaceThumbnail", with: "")
        }
        return "1"
    }
    
    // MARK: - Profile Images
    
    /// Maps profile image keys to asset names
    static func profileImageName(for key: Int?) -> String? {
        guard let key = key else { return nil }
        
        switch key {
        case 0: return "profile_gray"
        case 1: return "profile_blue"
        case 2: return "profile_pink"
        case 3: return "profile_purple"
        case 4: return "profile_green"
        case 5: return "profile_yellow"
        case 6: return "profile_blue_green"
        case 7: return "profile_orange"
        default: return nil
        }
    }
    
    /// Gets all available profile image names
    static var allProfileImages: [String] {
        ["profile_gray", "profile_blue", "profile_pink", "profile_purple",
         "profile_green", "profile_yellow", "profile_blue_green", "profile_orange"]
    }
    
    // MARK: - Background Textures
    
    /// Gets a random starfield texture name
    static func randomStarfieldTexture() -> String {
        let starfieldCount = 18
        let randomIndex = Int.random(in: 1...starfieldCount)
        return "Starfield-\(randomIndex)"
    }
    
    /// Gets starfield texture by index
    static func starfieldTexture(at index: Int) -> String {
        let clampedIndex = max(1, min(18, index))
        return "Starfield-\(clampedIndex)"
    }
    
    // MARK: - Category Icons
    
    /// Maps category to its 3D model filename
    static func modelFileName(for category: Category) -> String {
        switch category {
        case .ENTERTAINMENT:
            return "Enter.usdc"
        case .FAMILY:
            return "Family.usdz"
        case .PET:
            return "Pet.usdz"
        case .TRAVEL:
            return "Travel.usdc"
        }
    }
    
    // MARK: - Utility Functions
    
    /// Checks if an image exists in the asset catalog
    static func imageExists(named name: String) -> Bool {
        UIImage(named: name) != nil
    }
    
    /// Gets image with fallback
    static func image(named name: String, fallback: String) -> UIImage? {
        UIImage(named: name) ?? UIImage(named: fallback)
    }
}