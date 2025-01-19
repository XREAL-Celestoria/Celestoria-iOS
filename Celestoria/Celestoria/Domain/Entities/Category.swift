//
// Category.swift
//  Celestoria
//
//  Created by Park Seyoung on 1/20/25.
//

import Foundation
import SwiftUI

enum Category: String, CaseIterable, Codable {
    case ENTERTAINMENT
    case FAMILY
    case PET
    case TRAVEL
    
    var color: Color {
        switch self {
        case .ENTERTAINMENT: return .yellow    // 즐거운 엔터테인먼트를 상징
        case .FAMILY: return .blue            // 따뜻한 가족을 상징
        case .PET: return .green              // 자연과 생명을 상징
        case .TRAVEL: return .red             // 열정적인 여행을 상징
        }
    }
    
    var iconName: String {
        switch self {
        case .ENTERTAINMENT: return "party.popper"          // 엔터테인먼트/취미
        case .FAMILY: return "figure.2.and.child.holdinghands"  // 가족
        case .PET: return "pawprint.fill"                   // 반려동물
        case .TRAVEL: return "airplane"                     // 여행
        }
    }
    
    var displayName: String {
        switch self {
        case .ENTERTAINMENT: return "ENTERTAINMENT"
        case .FAMILY: return "FAMILY"
        case .PET: return "PET"
        case .TRAVEL: return "TRAVEL"
        }
    }
    
    var modelFileName: String {
        switch self {
        case .ENTERTAINMENT: return "Uranus.usdz"
        case .FAMILY: return "Neptune.usdz"
        case .PET: return "Mars.usdz"
        case .TRAVEL: return "Venus.usdz"
        }
    }
}
