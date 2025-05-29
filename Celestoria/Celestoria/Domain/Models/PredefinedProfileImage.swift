//
//  PredefinedProfileImage.swift
//  Celestoria
//
//  Created by Park Seyoung on 5/22/25.
//

import Foundation
import SwiftUI

enum PredefinedProfileImage: String, CaseIterable, Equatable {
    case profile_gray, profile_blue, profile_pink, profile_purple, profile_green, profile_yellow, profile_blue_green, profile_orange
    
    var key: Int {
            switch self {
            case .profile_gray: return 0
            case .profile_blue: return 1
            case .profile_pink: return 2
            case .profile_purple: return 3
            case .profile_green: return 4
            case .profile_yellow: return 5
            case .profile_blue_green: return 6
            case .profile_orange: return 7
            }
        }

        static func fromKey(_ key: Int) -> PredefinedProfileImage? {
            allCases.first { $0.key == key }
        }
}

enum ProfileImageSelection: Equatable {
    case custom(UIImage)
    case predefined(PredefinedProfileImage)

    var profileKey: Int? {
        if case .predefined(let image) = self {
            return image.key
        }
        return nil
    }

    var imageData: Data? {
        if case .custom(let image) = self {
            return image.jpegData(compressionQuality: 0.8)
        }
        return nil
    }
}
