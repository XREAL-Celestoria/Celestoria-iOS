//
//  Font+.swift
//  Celestoria
//
//  Created by Park Seyoung on 7/21/25.
//

import Foundation
import SwiftUI

enum Fonts {
    // XL Titles
    static let xlTitle1 = FontStyle(
        name: "XLTitle1",
        size: 48,
        lineHeight: 56,
        letterSpacing: 0,
        weight: .bold
    )
    
    static let xlTitle2 = FontStyle(
        name: "XLTitle2",
        size: 38,
        lineHeight: 46,
        letterSpacing: 0,
        weight: .bold
    )
    
    // Large Title
    static let largeTitle = FontStyle(
        name: "LargeTitle",
        size: 29,
        lineHeight: 38,
        letterSpacing: 0,
        weight: .bold
    )
    
    // Titles
    static let title1 = FontStyle(
        name: "Title1",
        size: 24,
        lineHeight: 32,
        letterSpacing: 0,
        weight: .bold
    )
    
    static let title1_2 = FontStyle(
        name: "Title1-2",
        size: 24,
        lineHeight: 32,
        letterSpacing: 0,
        weight: .semibold
    )
    
    static let title2 = FontStyle(
        name: "Title2",
        size: 22,
        lineHeight: 28,
        letterSpacing: 0,
        weight: .bold
    )
    
    static let title2_2 = FontStyle(
        name: "Title2-2",
        size: 22,
        lineHeight: 28,
        letterSpacing: 0,
        weight: .semibold
    )
    
    static let title3 = FontStyle(
        name: "Title3",
        size: 19,
        lineHeight: 24,
        letterSpacing: 0,
        weight: .bold
    )
    
    // Headline
    static let headline = FontStyle(
        name: "Headline",
        size: 17,
        lineHeight: 22,
        letterSpacing: 0,
        weight: .bold
    )
    
    // Body
    static let body1 = FontStyle(
        name: "Body1",
        size: 17,
        lineHeight: 22,
        letterSpacing: 0,
        weight: .medium
    )
    
    static let body2 = FontStyle(
        name: "Body2",
        size: 17,
        lineHeight: 22,
        letterSpacing: 0,
        weight: .regular
    )
    
    // Callout
    static let callout = FontStyle(
        name: "Callout",
        size: 15,
        lineHeight: 20,
        letterSpacing: 0,
        weight: .semibold
    )
    
    // Subheadline
    static let subheadline = FontStyle(
        name: "Subheadline",
        size: 15,
        lineHeight: 20,
        letterSpacing: 0,
        weight: .regular
    )
    
    // Footnote
    static let footnote = FontStyle(
        name: "Footnote",
        size: 13,
        lineHeight: 18,
        letterSpacing: 0,
        weight: .medium
    )
    
    // Captions
    static let caption1 = FontStyle(
        name: "Caption1",
        size: 12,
        lineHeight: 16,
        letterSpacing: 0,
        weight: .medium
    )
    
    static let caption2 = FontStyle(
        name: "Caption2",
        size: 12,
        lineHeight: 16,
        letterSpacing: 0,
        weight: .medium
    )
}

struct FontStyle {
    let name: String
    let size: CGFloat
    let lineHeight: CGFloat
    let letterSpacing: CGFloat
    let weight: Font.Weight
    
    func toFont() -> Font {
        return .system(size: size, weight: weight, design: .default)
    }
}
