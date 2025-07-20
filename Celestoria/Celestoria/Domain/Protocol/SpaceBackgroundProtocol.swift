//
//  SpaceBackgroundProtocol.swift
//  Celestoria
//
//  Created by Assistant on 7/20/25.
//

import Foundation

/// Protocol for space background configuration across platforms
protocol SpaceBackgroundConfigurable {
    var backgroundTextureName: String { get }
    var skyboxRadius: Float { get }
    var textureOptions: [String] { get }
    
    func randomBackgroundTexture() -> String
}

extension SpaceBackgroundConfigurable {
    var skyboxRadius: Float { 1000.0 }
    
    var textureOptions: [String] {
        (1...18).map { "Starfield-\($0)" }
    }
    
    func randomBackgroundTexture() -> String {
        textureOptions.randomElement() ?? "Starfield-1"
    }
}

/// Protocol for memory star display across platforms
protocol MemoryDisplayable {
    var id: UUID { get }
    var position: Position3D { get }
    var category: Category { get }
    var title: String { get }
    var videoURL: String? { get }
    var thumbnailURL: String? { get }
}

/// Protocol for 3D star animation
protocol StarAnimatable {
    var baseScale: Float { get }
    var pulseScale: Float { get }
    var pulseDuration: TimeInterval { get }
    
    func startPulseAnimation()
    func stopPulseAnimation()
}

extension StarAnimatable {
    var baseScale: Float { 3.0 }
    var pulseScale: Float { 3.2 }
    var pulseDuration: TimeInterval { 0.8 }
}