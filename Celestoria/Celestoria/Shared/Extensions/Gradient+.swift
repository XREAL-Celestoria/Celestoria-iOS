//
//  Gradient+.swift
//  Celestoria
//
//  Created by Park Seyoung on 1/20/25.
//

import Foundation
import SwiftUI

extension LinearGradient {
    static let GradientMain = LinearGradient(
        gradient: Gradient(colors: [Color.Main1, Color.Main2]),
        startPoint: .bottomLeading,
        endPoint: .topTrailing
    )
    
    static let GradientSub = LinearGradient(
        gradient: Gradient(colors: [Color.Sub1, Color.Sub2]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let GradientStroke = LinearGradient(
        gradient: Gradient(colors: [Color.Stroke1, Color.Stroke2]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let GradientIcon = LinearGradient(
        gradient: Gradient(colors: [Color.Icon1, Color.Icon2]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let BackgroundPopup = LinearGradient(
        gradient: Gradient(colors: [Color.Popup1, Color.Popup2]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let BackgroundSearch = LinearGradient(
        gradient: Gradient(colors: [Color.Search1, Color.Search2]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}
