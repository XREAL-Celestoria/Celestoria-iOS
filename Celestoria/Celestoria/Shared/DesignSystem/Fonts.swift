//
//  Font+.swift
//  Celestoria
//
//  Created by Park Seyoung on 7/21/25.
//

import Foundation
import SwiftUI

enum Fonts {
    // title
    static let title1 = FontStyle(
        name: "Pretendard-Bold",
        size: 28,
        lineHeight: 36.4,
        letterSpacing: -0.4
    )
    
    static let title2Bold = FontStyle(
        name: "Pretendard-Bold",
        size: 24,
        lineHeight: 31.2,
        letterSpacing: -0.4
    )
    
    static let title2SemiBold = FontStyle(
        name: "Pretendard-SemiBold",
        size: 24,
        lineHeight: 31.2,
        letterSpacing: -0.4
    )
    
    // heading
    static let heading1Bold = FontStyle(
        name: "Pretendard-Bold",
        size: 22,
        lineHeight: 28.6,
        letterSpacing: -0.4
    )
    
    static let heading1SemiBold = FontStyle(
        name: "Pretendard-SemiBold",
        size: 22,
        lineHeight: 28.6,
        letterSpacing: -0.4
    )
    
    static let heading2Bold = FontStyle(
        name: "Pretendard-Bold",
        size: 18,
        lineHeight: 23.4,
        letterSpacing: -0.4
    )
    
    static let heading3Bold = FontStyle(
        name: "Pretendard-Bold",
        size: 16,
        lineHeight: 20.8,
        letterSpacing: -0.4
    )
    
    static let heading2SemiBold = FontStyle(
        name: "Pretendard-SemiBold",
        size: 18,
        lineHeight: 23.4,
        letterSpacing: -0.4
    )
    
    static let heading2Medium = FontStyle(
        name: "Pretendard-Medium",
        size: 18,
        lineHeight: 23.4,
        letterSpacing: -0.4
    )
    
    static let heading3Medium = FontStyle(
        name: "Pretendard-Medium",
        size: 16,
        lineHeight: 20.8,
        letterSpacing: -0.4
    )
    
    static let heading3Regular = FontStyle(
        name: "Pretendard-Regular",
        size: 16,
        lineHeight: 20.8,
        letterSpacing: -0.4
    )
    
    // body
    static let body1SemiBold = FontStyle(
        name: "Pretendard-SemiBold",
        size: 14,
        lineHeight: 21.0,
        letterSpacing: -0.4
    )
    
    static let body1Medium = FontStyle(
        name: "Pretendard-Medium",
        size: 14,
        lineHeight: 21.0,
        letterSpacing: -0.4
    )
    
    static let body2SemiBold = FontStyle(
        name: "Pretendard-SemiBold",
        size: 12,
        lineHeight: 18.0,
        letterSpacing: -0.4
    )
    
    static let body2Medium = FontStyle(
        name: "Pretendard-Medium",
        size: 12,
        lineHeight: 18.0,
        letterSpacing: -0.4
    )
    
    static let body2Regular = FontStyle(
        name: "Pretendard-Regular",
        size: 12,
        lineHeight: 18.0,
        letterSpacing: -0.4
    )
    
    static let caption1Medium = FontStyle(
        name: "Pretendard-Medium",
        size: 11,
        lineHeight: 16.5,
        letterSpacing: -0.4
    )
    
    static let caption1Regular = FontStyle(
        name: "Pretendard-Regular",
        size: 11,
        lineHeight: 16.5,
        letterSpacing: -0.4
    )
    
    static let caption1Semibold = FontStyle(
        name: "Pretendard-SemiBold",
        size: 11,
        lineHeight: 16.5,
        letterSpacing: -0.4
    )
    
    static let caption2 = FontStyle(
        name: "Pretendard-Regular",
        size: 9,
        lineHeight: 13.5,
        letterSpacing: -0.4
    )
}

struct FontStyle {
    let name: String
    let size: CGFloat
    let lineHeight: CGFloat
    let letterSpacing: CGFloat

    func toFont() -> Font {
        Font.custom(name, size: size)
    }
}
