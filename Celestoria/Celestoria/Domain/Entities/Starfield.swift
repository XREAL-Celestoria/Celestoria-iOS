//
//  Starfield.swift
//  Celestoria
//
//  Created by Park Seyoung on 1/25/25.
//

import Foundation

enum Starfield: String, CaseIterable {
    case YELLOW
    case RED
    case BLUE
    case PURPLEGREEN
    case PURPLE

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
        }
    }

    // 랜덤하게 Starfield enum 값을 반환
    static func random() -> Starfield {
        return Starfield.allCases.randomElement()!
    }
}
