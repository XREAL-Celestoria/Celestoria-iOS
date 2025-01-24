//
//  Gradient+.swift
//  Celestoria
//
//  Created by Park Seyoung on 1/20/25.
//

import Foundation
import SwiftUI

extension LinearGradient {
    // Design System
    static let GradientMain = LinearGradient(
        gradient: Gradient(colors: [Color.Main1, Color.Main2]),
        startPoint: .bottomLeading,
        endPoint: .topTrailing
    )
    
    static let GradientSub = LinearGradient(
        gradient: Gradient(colors: [Color.Sub1, Color.Sub2]),
        startPoint: .top,
        endPoint: .bottom
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
        gradient: Gradient(stops: [
            Gradient.Stop(color: Color.Popup1, location: 0.0),
            Gradient.Stop(color: Color.Popup2, location: 0.65),
            Gradient.Stop(color: Color.Popup3, location: 1.0)
        ]),
        startPoint: .top,
        endPoint: .bottom
    )
    
    static let StrokePopup = LinearGradient(
        gradient: Gradient(colors: [Color.NebulaWhite, Color(hex: "CCCCCC")]),
        startPoint: .top,
        endPoint: .bottom
    )
    
    static let BackgroundSearch = LinearGradient(
        gradient: Gradient(colors: [Color.Search1, Color.Search2]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // Other
    static let MainTabButtonBackground = LinearGradient(
        gradient: Gradient(stops: [
            Gradient.Stop(color: Color(hex: "#FFFFFF", opacity: 0.5), location: 0.0),
            Gradient.Stop(color: Color(hex: "#EBEBEB", opacity: 0.37), location: 0.2),
            Gradient.Stop(color: Color(hex: "#E0E0E0", opacity: 0.29), location: 0.28),
            Gradient.Stop(color: Color(hex: "#D4D4D4", opacity: 0.21), location: 0.4),
            Gradient.Stop(color: Color(hex: "#CFCFCF", opacity: 0.18), location: 0.48),
            Gradient.Stop(color: Color(hex: "#CACACA", opacity: 0.14), location: 0.54),
            Gradient.Stop(color: Color(hex: "#C8C8C8", opacity: 0.13), location: 0.59),
            Gradient.Stop(color: Color(hex: "#C4C4C4", opacity: 0.10), location: 0.67),
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let MainTabButtonStroke = LinearGradient(
        gradient: Gradient(stops: [
            Gradient.Stop(color: Color(hex: "#FFFFFF", opacity: 0.2), location: 0.0),
            Gradient.Stop(color: Color(hex: "#00000", opacity: 0), location: 0.5),
            Gradient.Stop(color: Color(hex: "#FFFFF", opacity: 0.2), location: 1.0)
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
}
