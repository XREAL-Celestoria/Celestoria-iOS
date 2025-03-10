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
        case .ENTERTAINMENT: return "Entertainment"          // 엔터테인먼트/취미
        case .FAMILY: return "Family"  // 가족
        case .PET: return "Pet"                   // 반려동물
        case .TRAVEL: return "Travel"                     // 여행
        }
    }
    
    var displayName: String {
        switch self {
        case .ENTERTAINMENT: return "Entertainment"
        case .FAMILY: return "Family"
        case .PET: return "Pet"
        case .TRAVEL: return "Travel"
        }
    }
    
    var modelFileName: String {
        switch self {
        case .ENTERTAINMENT: return "Enter.usdc"
        case .FAMILY: return "Family.usdz"
        case .PET: return "Pet.usdz"
        case .TRAVEL: return "Travel.usdc"
        }
    }
}
