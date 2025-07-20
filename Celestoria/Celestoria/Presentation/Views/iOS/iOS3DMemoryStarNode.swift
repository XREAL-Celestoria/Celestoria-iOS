//
//  iOS3DMemoryStarNode.swift
//  Celestoria
//
//  Created by Minjun Kim on 7/20/25.
//


import SceneKit
import AVFoundation

class iOS3DMemoryStarNode: SCNNode {
    let memory: Memory
    private var starNode: SCNNode?
    private var pulseAction: SCNAction?
    
    private enum Constants {
        static let starRadius: Float = 0.3
        static let pulseScale: Float = 1.2
        static let initialScale: Float = 1.0
        static let pulseDuration: TimeInterval = 1.5
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
        let geometry: SCNGeometry
        
        switch memory.category {
        case .FAMILY:
            geometry = createStarGeometry(color: UIColor(red: 1.0, green: 0.8, blue: 0.8, alpha: 1.0))
        case .TRAVEL:
            geometry = createStarGeometry(color: UIColor(red: 0.8, green: 0.9, blue: 1.0, alpha: 1.0))
        case .PET:
            geometry = createStarGeometry(color: UIColor(red: 0.8, green: 1.0, blue: 0.8, alpha: 1.0))
        case .ENTERTAINMENT:
            geometry = createStarGeometry(color: UIColor(red: 1.0, green: 0.9, blue: 0.7, alpha: 1.0))
        }
        
        starNode = SCNNode(geometry: geometry)
        addChildNode(starNode!)
        
        let light = SCNLight()
        light.type = .omni
        light.color = UIColor.white
        light.intensity = 200
        light.attenuationStartDistance = 0.1
        light.attenuationEndDistance = 2.0
        
        let lightNode = SCNNode()
        lightNode.light = light
        addChildNode(lightNode)
    }
    
    private func createStarGeometry(color: UIColor) -> SCNGeometry {
        let sphere = SCNSphere(radius: CGFloat(Constants.starRadius))
        sphere.segmentCount = 24
        
        let material = SCNMaterial()
        material.diffuse.contents = color
        material.emission.contents = color
        material.emission.intensity = 0.3
        material.specular.contents = UIColor.white
        material.shininess = 50
        
        sphere.materials = [material]
        return sphere
    }
    
    private func setupPhysics() {
        let shape = SCNPhysicsShape(geometry: SCNSphere(radius: CGFloat(Constants.starRadius)), options: nil)
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