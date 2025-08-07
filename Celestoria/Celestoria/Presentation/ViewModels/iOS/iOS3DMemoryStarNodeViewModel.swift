//
//  iOS3DMemoryStarNodeViewModel.swift
//  Celestoria
//
//  Created by Assistant on 1/28/25.
//

import Foundation
import SceneKit
import UIKit
import os

@MainActor
final class iOS3DMemoryStarNodeViewModel: ObservableObject {
    // MARK: - Dependencies
    private let logger = Logger(subsystem: "Celestoria", category: "iOS3DMemoryStarNodeViewModel")
    
    // MARK: - Published Properties
    @Published private(set) var memory: Memory
    @Published var isAnimating: Bool = false
    @Published var isHighlighted: Bool = false
    
    // MARK: - Constants
    private enum Constants {
        static let starRadius: Float = 0.5
        static let initialScale: Float = 3.0
        static let pulseScale: Float = 3.2
        static let glowIntensity: Float = 0.8
        static let animationDuration: TimeInterval = 0.3
        static let pulseDuration: TimeInterval = 0.8
        static let hitRadiusMultiplier: Float = 2.0
    }
    
    // MARK: - Computed Properties
    var position: SCNVector3 {
        SCNVector3(
            x: Float(memory.position.x),
            y: Float(memory.position.y),
            z: Float(memory.position.z)
        )
    }
    
    var modelFileName: String {
        memory.category.modelFileName
    }
    
    var categoryColor: UIColor {
        switch memory.category {
        case .FAMILY:
            return UIColor(red: 1.0, green: 0.8, blue: 0.8, alpha: 1.0)
        case .TRAVEL:
            return UIColor(red: 0.8, green: 0.9, blue: 1.0, alpha: 1.0)
        case .PET:
            return UIColor(red: 0.8, green: 1.0, blue: 0.8, alpha: 1.0)
        case .ENTERTAINMENT:
            return UIColor(red: 1.0, green: 0.9, blue: 0.7, alpha: 1.0)
        }
    }
    
    var initialScale: SCNVector3 {
        SCNVector3(Constants.initialScale, Constants.initialScale, Constants.initialScale)
    }
    
    var pulseScale: SCNVector3 {
        SCNVector3(Constants.pulseScale, Constants.pulseScale, Constants.pulseScale)
    }
    
    var starRadius: Float {
        Constants.starRadius
    }
    
    var hitRadius: Float {
        Constants.starRadius * Constants.hitRadiusMultiplier
    }
    
    var glowIntensity: CGFloat {
        CGFloat(Constants.glowIntensity)
    }
    
    // MARK: - Initialization
    init(memory: Memory) {
        self.memory = memory
        logger.info("iOS3DMemoryStarNodeViewModel initialized for memory: \(memory.id.uuidString)")
    }
    
    // MARK: - Model Loading Logic
    func getModelResourceInfo() -> (baseName: String, fileExtension: String) {
        let modelFileName = self.modelFileName
        let baseName = modelFileName.replacingOccurrences(of: ".usdz", with: "").replacingOccurrences(of: ".usdc", with: "")
        let fileExtension = modelFileName.hasSuffix(".usdz") ? "usdz" : "usdc"
        return (baseName, fileExtension)
    }
    
    func getModelURL() -> URL? {
        let (baseName, fileExtension) = getModelResourceInfo()
        return Bundle.main.url(forResource: baseName, withExtension: fileExtension)
    }
    
    func shouldUseFallback() -> Bool {
        return getModelURL() == nil
    }
    
    // MARK: - Animation Logic
    func createPulseAnimation() -> SCNAction {
        let scaleUp = SCNAction.scale(to: CGFloat(Constants.pulseScale), duration: Constants.pulseDuration)
        scaleUp.timingMode = .easeInEaseOut
        
        let scaleDown = SCNAction.scale(to: CGFloat(Constants.initialScale), duration: Constants.pulseDuration)
        scaleDown.timingMode = .easeInEaseOut
        
        let sequence = SCNAction.sequence([scaleUp, scaleDown])
        return SCNAction.repeatForever(sequence)
    }
    
    func createMoveAnimation(to newPosition: SCNVector3) -> SCNAction {
        return SCNAction.move(to: newPosition, duration: 0.5)
    }
    
    func createHighlightAnimation(for material: SCNMaterial) -> SCNAction {
        let originalEmissionIntensity = material.emission.intensity
        
        let brighten = SCNAction.customAction(duration: 0.2) { _, elapsedTime in
            material.emission.intensity = originalEmissionIntensity + 0.5 * CGFloat(elapsedTime / 0.2)
        }
        
        let dim = SCNAction.customAction(duration: 0.2) { _, elapsedTime in
            material.emission.intensity = (originalEmissionIntensity + 0.5) - 0.5 * CGFloat(elapsedTime / 0.2)
        }
        
        return SCNAction.sequence([brighten, dim])
    }
    
    // MARK: - State Management
    func startAnimation() {
        isAnimating = true
        logger.debug("Started animation for memory: \(self.memory.id.uuidString)")
    }
    
    func stopAnimation() {
        isAnimating = false
        logger.debug("Stopped animation for memory: \(self.memory.id.uuidString)")
    }
    
    func setHighlighted(_ highlighted: Bool) {
        isHighlighted = highlighted
        logger.debug("Set highlighted \(highlighted) for memory: \(self.memory.id.uuidString)")
    }
    
    // MARK: - Memory Updates
    func updateMemory(_ newMemory: Memory) {
        logger.info("Updating memory from \(self.memory.id.uuidString) to \(newMemory.id.uuidString)")
        self.memory = newMemory
    }
    
    // MARK: - Material Configuration
    func configureFallbackMaterial() -> SCNMaterial {
        let material = SCNMaterial()
        material.diffuse.contents = categoryColor
        material.emission.contents = categoryColor
        material.emission.intensity = 0.3
        material.specular.contents = UIColor.white
        material.shininess = 50
        return material
    }
    
    func configureGlowEffect(for material: SCNMaterial) {
        if material.emission.contents == nil {
            material.emission.contents = material.diffuse.contents
        }
        material.emission.intensity = glowIntensity
    }
    
    // MARK: - Physics Configuration
    func createPhysicsShape() -> SCNPhysicsShape {
        let sphere = SCNSphere(radius: CGFloat(hitRadius))
        return SCNPhysicsShape(geometry: sphere, options: nil)
    }
    
    // MARK: - Lighting Configuration
    func createLightNode() -> SCNNode {
        let light = SCNLight()
        light.type = .omni
        light.color = UIColor.white
        light.intensity = 200
        light.attenuationStartDistance = 0.1
        light.attenuationEndDistance = 2.0
        
        let lightNode = SCNNode()
        lightNode.light = light
        return lightNode
    }
    
    // MARK: - Geometry Configuration
    func createFallbackGeometry() -> SCNGeometry {
        let sphere = SCNSphere(radius: CGFloat(starRadius))
        sphere.segmentCount = 24
        sphere.materials = [configureFallbackMaterial()]
        return sphere
    }
    
    // MARK: - Logging
    func logModelLoadSuccess() {
        let (baseName, fileExtension) = getModelResourceInfo()
        Logger.info("Successfully loaded 3D model: \(baseName).\(fileExtension) for category: \(memory.category)")
    }
    
    func logModelLoadError(_ error: Error) {
        let (baseName, fileExtension) = getModelResourceInfo()
        logger.error("Error loading 3D model \(baseName).\(fileExtension): \(error.localizedDescription)")
    }
    
    func logFallbackUsage() {
        let (baseName, fileExtension) = getModelResourceInfo()
        Logger.warning("3D model file not found: \(baseName).\(fileExtension), using fallback for category: \(memory.category)")
    }
}
