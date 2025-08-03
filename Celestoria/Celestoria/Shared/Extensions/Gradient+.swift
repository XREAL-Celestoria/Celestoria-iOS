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
        gradient: Gradient(colors: [Colors.Main1, Colors.Main2]),
        startPoint: .bottomLeading,
        endPoint: .topTrailing
    )
    
    static let GradientSub = LinearGradient(
        gradient: Gradient(colors: [Colors.Sub1, Colors.Sub2]),
        startPoint: .top,
        endPoint: .bottom
    )
    
    static let GradienBeforeSelect = LinearGradient(
        gradient: Gradient(colors: [Color(hex: "AAB8C6"), Color(hex: "839DBA")]),
        startPoint: .top,
        endPoint: .bottom
    )
    
    static let GradientStroke = LinearGradient(
        gradient: Gradient(colors: [Colors.Stroke1, Colors.Stroke2]),
        startPoint: .top,
        endPoint: .bottom
    )
    
    static let GradientIcon = LinearGradient(
        gradient: Gradient(colors: [Colors.Icon1, Colors.Icon2]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let GradientCard = LinearGradient(
        gradient: Gradient(colors: [Color(hex: "A7E9FE"), Color(hex: "515768")]),
        startPoint: .top,
        endPoint: .bottom
    )
    
    static let GradientCardOverlay = LinearGradient(
        gradient: Gradient(colors: [Colors.NebulaWhite.opacity(0), Colors.NebulaBlack.opacity(0.7)]),
        startPoint: .top,
        endPoint: .bottom
    )
    
    static let BackgroundPopup = LinearGradient(
        gradient: Gradient(stops: [
            Gradient.Stop(color: Colors.Popup1, location: 0.0),
            Gradient.Stop(color: Colors.Popup2, location: 0.65),
            Gradient.Stop(color: Colors.Popup3, location: 1.0)
        ]),
        startPoint: .top,
        endPoint: .bottom
    )
    
    static let StrokePopup = LinearGradient(
        gradient: Gradient(colors: [Colors.NebulaWhite, Color(hex: "CCCCCC")]),
        startPoint: .top,
        endPoint: .bottom
    )
    
    static let BackgroundSearch = LinearGradient(
        gradient: Gradient(colors: [Colors.Search1, Colors.Search2]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // Design Tokens - Gradients
    static let SubGradient = LinearGradient(
        gradient: Gradient(colors: [Color(hex: "#a7e9fe"), Color(hex: "#b5c9ff")]),
        startPoint: .top,
        endPoint: .bottom
    )
    
    static let MainGradient = LinearGradient(
        gradient: Gradient(colors: [Color(hex: "#babcff"), Color(hex: "#cff4ff")]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let MainStroke = LinearGradient(
        gradient: Gradient(colors: [Color(hex: "#ffffff"), Color(hex: "#cdefff")]),
        startPoint: .top,
        endPoint: .bottom
    )
    
    static let PopupStroke = LinearGradient(
        gradient: Gradient(colors: [Color(hex: "#ffffff"), Color(hex: "#cccccc")]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let IconGradient = LinearGradient(
        gradient: Gradient(colors: [Color(hex: "#cff4ff"), Color(hex: "#babcff")]),
        startPoint: .top,
        endPoint: .bottom
    )
    
    static let PopupMain = LinearGradient(
        gradient: Gradient(stops: [
            Gradient.Stop(color: Color(hex: "#17171733"), location: 0.0),
            Gradient.Stop(color: Color(hex: "#4b4b4b33"), location: 0.65),
            Gradient.Stop(color: Color(hex: "#54c3ff80"), location: 1.0)
        ]),
        startPoint: .top,
        endPoint: .bottom
    )
    
    static let SearchUsercardBG = LinearGradient(
        gradient: Gradient(colors: [Color(hex: "#a7e9fe"), Color(hex: "#515768")]),
        startPoint: .top,
        endPoint: .bottom
    )
    
    static let BtnFillColor = LinearGradient(
        gradient: Gradient(colors: [Color(hex: "#a7e9fe"), Color(hex: "#b5c9ff")]),
        startPoint: .top,
        endPoint: .bottom
    )
    
    static let BtnStroke = LinearGradient(
        gradient: Gradient(colors: [Color(hex: "#ffffff"), Color(hex: "#cdefff")]),
        startPoint: .top,
        endPoint: .bottom
    )
    
    static let CheckedBoxStroke = LinearGradient(
        gradient: Gradient(colors: [Color(hex: "#a7e9fe"), Color(hex: "#b5c9ff")]),
        startPoint: .top,
        endPoint: .bottom
    )
    
    static let BtnAfterSelect = LinearGradient(
        gradient: Gradient(colors: [Color(hex: "#a7e9fe"), Color(hex: "#b5c9ff")]),
        startPoint: .top,
        endPoint: .bottom
    )
    
    static let BtnBeforeSelect = LinearGradient(
        gradient: Gradient(colors: [Color(hex: "#aab8c6"), Color(hex: "#839dba")]),
        startPoint: .top,
        endPoint: .bottom
    )
    
    static let DimBlackGradation = LinearGradient(
        gradient: Gradient(colors: [Color(hex: "#00000000"), Color(hex: "#000000b2")]),
        startPoint: .top,
        endPoint: .bottom
    )
    
    static let DimSkyblueGradation = LinearGradient(
        gradient: Gradient(stops: [
            Gradient.Stop(color: Color(hex: "#17171733"), location: 0.0),
            Gradient.Stop(color: Color(hex: "#4b4b4b33"), location: 0.51),
            Gradient.Stop(color: Color(hex: "#217aaa80"), location: 1.0)
        ]),
        startPoint: .top,
        endPoint: .bottom
    )
    
    static let BtnBackGrad = LinearGradient(
        gradient: Gradient(colors: [Color(hex: "#14141500"), Color(hex: "#141415")]),
        startPoint: .top,
        endPoint: .bottom
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
