//
//  Starfield.swift
//  Celestoria
//
//  Created by Park Seyoung on 1/26/25.


import Foundation
import SwiftUI

enum StarField: String, CaseIterable {
    case FIELD_1
    case FIELD_2
    case FIELD_3
    case FIELD_4
    case FIELD_5
    case FIELD_6
    case ORORABLUE
    case ORORABLUEGRAY
    case ORORABLUEPURPLE
    case ORORAGREEN
    case ORORAPURPLE
    case ORORAPINK
    case YELLOW
    case RED
    case BLUE
    case PURPLEGREEN
    case PURPLE
    case GRAY

    var imageName: String {
        switch self {
        case .FIELD_1:
            return "Starfield-1"
        case .FIELD_2:
            return "Starfield-2"
        case .FIELD_3:
            return "Starfield-3"
        case .FIELD_4:
            return "Starfield-4"
        case .FIELD_5:
            return "Starfield-5"
        case .FIELD_6:
            return "Starfield-6"
        case .ORORABLUE:
            return "Starfield-orora-blue"
        case .ORORABLUEGRAY:
            return "Starfield-orora-blueGray"
        case .ORORABLUEPURPLE:
            return "Starfield-orora-bluePurple"
        case .ORORAGREEN:
            return "Starfield-orora-green"
        case .ORORAPURPLE:
            return "Starfield-orora-purple"
        case .ORORAPINK:
            return "Starfield-orora-pink"
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
