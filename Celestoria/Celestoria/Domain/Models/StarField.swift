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
    case FIELD_7
    case FIELD_8
    case FIELD_9
    case FIELD_10
    case FIELD_11
    case FIELD_12
    case FIELD_13
    case FIELD_14
    case FIELD_15
    case FIELD_16
    case FIELD_17
    case FIELD_18

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
        case .FIELD_7:
            return "Starfield-7"
        case .FIELD_8:
            return "Starfield-8"
        case .FIELD_9:
            return "Starfield-9"
        case .FIELD_10:
            return "Starfield-10"
        case .FIELD_11:
            return "Starfield-11"
        case .FIELD_12:
            return "Starfield-12"
        case .FIELD_13:
            return "Starfield-13"
        case .FIELD_14:
            return "Starfield-14"
        case .FIELD_15:
            return "Starfield-15"
        case .FIELD_16:
            return "Starfield-16"
        case .FIELD_17:
            return "Starfield-17"
        case .FIELD_18:
            return "Starfield-18"
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
