//
//  Color+.swift
//  Celestoria
//
//  Created by Park Seyoung on 1/20/25.
//

import SwiftUI

extension Color {
    // Gradient
    static let Main1 = Color(hex: "BABCFF")
    static let Main2 = Color(hex: "CFF4FF")
    static let Sub1 = Color(hex: "B5C9FF")
    static let Sub2 = Color(hex: "A7E9FE")
    static let Stroke1 = Color(hex: "FFFFFF")
    static let Stroke2 = Color(hex: "CDEFFF")
    static let Icon1 = Color(hex: "CFF4FF")
    static let Icon2 = Color(hex: "BABCFF")
    
    // Background
    static let Popup1 = Color(hex: "171717")
    static let Popup2 = Color(hex: "54C3FF")
    static let Profile = Color(hex: "272938")
    static let Search1 = Color(hex: "A7E9FE")
    static let Search2 = Color(hex: "515768")
    
    // Text
    static let NebulaWhite = Color(hex: "FFFFFF")
    static let NebulaRed = Color(hex: "FF3B3E")
    static let NebulaBlack = Color(hex: "090909")
    static let Placeholder = Color(hex: "9D9D9D")
    
    init(hex: String, opacity: Double = 1.0) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        
        let r, g, b: Double
        switch hex.count {
        case 3: // 3자리 Hex 코드 처리
            (r, g, b) = (
                Double((int >> 8) * 17) / 255,
                Double((int >> 4 & 0xF) * 17) / 255,
                Double((int & 0xF) * 17) / 255
            )
        case 6: // 6자리 Hex 코드 처리
            (r, g, b) = (
                Double((int >> 16) & 0xFF) / 255,
                Double((int >> 8) & 0xFF) / 255,
                Double(int & 0xFF) / 255
            )
        case 8: // 8자리 Hex 코드 처리 (알파 포함)
            let a = Double((int >> 24) & 0xFF) / 255
            (r, g, b) = (
                Double((int >> 16) & 0xFF) / 255,
                Double((int >> 8) & 0xFF) / 255,
                Double(int & 0xFF) / 255
            )
            self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
            return
        default:
            (r, g, b) = (1, 1, 1) // 기본값: 흰색
        }
        
        self.init(.sRGB, red: r, green: g, blue: b, opacity: opacity)
    }
}
