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

    var uiImage: UIImage? {
        UIImage(named: self.rawValue)
    }
}

