//
//  iOS3DMemoryStarNode.swift
//  Celestoria
//
//  Created by Minjun Kim on 7/20/25.
//


import SceneKit
import AVFoundation
import UIKit

class iOS3DMemoryStarNode: SCNNode {
    let memory: Memory
    private var starNode: SCNNode?
    private var pulseAction: SCNAction?
    
    private enum Constants {
        static let starRadius: Float = 0.5  // Increased for better visibility
        static let initialScale: Float = 3.0  // Same as visionOS
        static let pulseScale: Float = 3.2    // Same as visionOS
        static let glowIntensity: Float = 0.8
        static let animationDuration: TimeInterval = 0.3
        static let pulseDuration: TimeInterval = 0.8
    }
    
    init(memory: Memory) {
        self.memory = memory
        super.init()
        
        setupPosition()
        setupStarModel()
        setupPhysics()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupPosition() {
        // Use position from memory
        position = SCNVector3(
            x: Float(memory.position.x),
            y: Float(memory.position.y),
            z: Float(memory.position.z)
        )
    }
    
    private func setupStarModel() {
        // Load 3D model based on category (same as visionOS)
        let modelFileName = memory.category.modelFileName
        let baseName = modelFileName.replacingOccurrences(of: ".usdz", with: "").replacingOccurrences(of: ".usdc", with: "")
        let fileExtension = modelFileName.hasSuffix(".usdz") ? "usdz" : "usdc"
        
        // iOS loads directly from bundle root, not from RealityKit/Entities subfolder
        if let modelURL = Bundle.main.url(forResource: baseName, withExtension: fileExtension) {
            do {
                print("Loading 3D model: \(baseName).\(fileExtension)")
                let modelScene = try SCNScene(url: modelURL, options: nil)
                
                // Clone the entire scene's content
                starNode = SCNNode()
                for child in modelScene.rootNode.childNodes {
                    starNode!.addChildNode(child.clone())
                }
                
                // Apply scale to match visionOS
                starNode!.scale = SCNVector3(Constants.initialScale, Constants.initialScale, Constants.initialScale)
                addChildNode(starNode!)
                
                // Add glow effect to all materials
                addGlowEffect(to: starNode!)
                
                // Start pulse animation
                startPulseAnimation()
                
                print("Successfully loaded 3D model for category: \(memory.category)")
                return
            } catch {
                print("Error loading 3D model from \(modelURL): \(error)")
            }
        } else {
            print("3D model file not found: \(baseName).\(fileExtension)")
        }
        
        // Fallback to colored sphere
        setupFallbackStar()
    }
    
    private func setupFallbackStar() {
        print("Using fallback colored sphere for category: \(memory.category)")
        
        let geometry: SCNGeometry
        let color: UIColor
        
        switch memory.category {
        case .FAMILY:
            color = UIColor(red: 1.0, green: 0.8, blue: 0.8, alpha: 1.0)
        case .TRAVEL:
            color = UIColor(red: 0.8, green: 0.9, blue: 1.0, alpha: 1.0)
        case .PET:
            color = UIColor(red: 0.8, green: 1.0, blue: 0.8, alpha: 1.0)
        case .ENTERTAINMENT:
            color = UIColor(red: 1.0, green: 0.9, blue: 0.7, alpha: 1.0)
        }
        
        let sphere = SCNSphere(radius: CGFloat(Constants.starRadius))
        sphere.segmentCount = 24
        
        let material = SCNMaterial()
        material.diffuse.contents = color
        material.emission.contents = color
        material.emission.intensity = 0.3
        material.specular.contents = UIColor.white
        material.shininess = 50
        
        sphere.materials = [material]
        
        starNode = SCNNode(geometry: sphere)
        starNode!.scale = SCNVector3(Constants.initialScale, Constants.initialScale, Constants.initialScale)
        addChildNode(starNode!)
        
        // Add light for visibility
        let light = SCNLight()
        light.type = .omni
        light.color = UIColor.white
        light.intensity = 200
        light.attenuationStartDistance = 0.1
        light.attenuationEndDistance = 2.0
        
        let lightNode = SCNNode()
        lightNode.light = light
        addChildNode(lightNode)
        
        // Start pulse animation
        startPulseAnimation()
    }
    
    private func addGlowEffect(to node: SCNNode) {
        // Add emission material for glow effect
        if let geometry = node.geometry {
            for material in geometry.materials {
                // Enhance existing materials with glow
                if material.emission.contents == nil {
                    material.emission.contents = material.diffuse.contents
                }
                material.emission.intensity = CGFloat(Constants.glowIntensity)
            }
        }
        
        // Recursively apply to child nodes
        for child in node.childNodes {
            addGlowEffect(to: child)
        }
    }
    
    private func setupPhysics() {
        // Use larger radius for better hit detection
        let hitRadius = Constants.starRadius * 2.0
        let shape = SCNPhysicsShape(geometry: SCNSphere(radius: CGFloat(hitRadius)), options: nil)
        physicsBody = SCNPhysicsBody(type: .static, shape: shape)
        physicsBody?.isAffectedByGravity = false
    }
    
    func startPulseAnimation() {
        let scaleUp = SCNAction.scale(to: CGFloat(Constants.pulseScale), duration: Constants.pulseDuration)
        scaleUp.timingMode = .easeInEaseOut
        
        let scaleDown = SCNAction.scale(to: CGFloat(Constants.initialScale), duration: Constants.pulseDuration)
        scaleDown.timingMode = .easeInEaseOut
        
        let sequence = SCNAction.sequence([scaleUp, scaleDown])
        pulseAction = SCNAction.repeatForever(sequence)
        
        starNode?.runAction(pulseAction!)
    }
    
    func stopPulseAnimation() {
        starNode?.removeAllActions()
    }
    
    func updateMemory(_ memory: Memory) {
        let moveAction = SCNAction.move(to: SCNVector3(
            x: Float(memory.position.x),
            y: Float(memory.position.y),
            z: Float(memory.position.z)
        ), duration: 0.5)
        runAction(moveAction)
    }
    
    func highlightStar() {
        guard let material = starNode?.geometry?.firstMaterial else { return }
        
        let originalEmissionIntensity = material.emission.intensity
        
        let brighten = SCNAction.customAction(duration: 0.2) { _, elapsedTime in
            material.emission.intensity = originalEmissionIntensity + 0.5 * CGFloat(elapsedTime / 0.2)
        }
        
        let dim = SCNAction.customAction(duration: 0.2) { _, elapsedTime in
            material.emission.intensity = (originalEmissionIntensity + 0.5) - 0.5 * CGFloat(elapsedTime / 0.2)
        }
        
        let sequence = SCNAction.sequence([brighten, dim])
        starNode?.runAction(sequence)
    }
}