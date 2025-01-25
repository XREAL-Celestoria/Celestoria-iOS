//
//  Starfield.swift
//  Celestoria
//
//  Created by Park Seyoung on 1/26/25.


import Foundation
import SwiftUI

enum StarField: String, CaseIterable {
    case YELLOW
    case RED
    case BLUE
    case PURPLEGREEN
    case PURPLE
    case GRAY

    var imageName: String {
        switch self {
        case .YELLOW:
            return "Starfield-yellow"
        case .RED:
            return "Starfield-red"
        case .BLUE:
            return "Starfield-blue"
        case .PURPLEGREEN:
            return "Starfield-purpleGreen"
        case .PURPLE:
            return "Starfield-purple"
        case .GRAY:
            return "Starfield-gray"
        }
    }

    // 랜덤하게 Starfield enum 값을 반환
    static func random() -> StarField {
        return StarField.allCases.randomElement()!
    }
    
    init?(imageName: String) {
        if let matchedCase = StarField.allCases.first(where: { $0.imageName == imageName }) {
            self = matchedCase
        } else {
            return nil 
        }
    }
}
