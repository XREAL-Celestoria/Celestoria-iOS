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
    private let viewModel: iOS3DMemoryStarNodeViewModel
    private var starNode: SCNNode?
    private var pulseAction: SCNAction?
    
    var memory: Memory {
        viewModel.memory
    }
    
    init(memory: Memory) {
        self.viewModel = iOS3DMemoryStarNodeViewModel(memory: memory)
        super.init()
        
        setupPosition()
        setupStarModel()
        setupPhysics()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupPosition() {
        // Use position from viewModel
        position = viewModel.position
    }
    
    private func setupStarModel() {
        // Check if we should use fallback or try to load 3D model
        if viewModel.shouldUseFallback() {
            viewModel.logFallbackUsage()
            setupFallbackStar()
            return
        }
        
        // Try to load 3D model using viewModel
        guard let modelURL = viewModel.getModelURL() else {
            viewModel.logFallbackUsage()
            setupFallbackStar()
            return
        }
        
        do {
            let (baseName, fileExtension) = viewModel.getModelResourceInfo()
            print("Loading 3D model: \(baseName).\(fileExtension)")
            let modelScene = try SCNScene(url: modelURL, options: nil)
            
            // Clone the entire scene's content
            starNode = SCNNode()
            for child in modelScene.rootNode.childNodes {
                starNode!.addChildNode(child.clone())
            }
            
            // Apply scale from viewModel
            starNode!.scale = viewModel.initialScale
            addChildNode(starNode!)
            
            // Add glow effect to all materials
            addGlowEffect(to: starNode!)
            
            // Start pulse animation
            startPulseAnimation()
            
            viewModel.logModelLoadSuccess()
        } catch {
            viewModel.logModelLoadError(error)
            setupFallbackStar()
        }
    }
    
    private func setupFallbackStar() {
        print("Using fallback colored sphere for category: \(memory.category)")
        
        // Create geometry and material using viewModel
        let geometry = viewModel.createFallbackGeometry()
        
        starNode = SCNNode(geometry: geometry)
        starNode!.scale = viewModel.initialScale
        addChildNode(starNode!)
        
        // Add light for visibility using viewModel
        let lightNode = viewModel.createLightNode()
        addChildNode(lightNode)
        
        // Start pulse animation
        startPulseAnimation()
    }
    
    private func addGlowEffect(to node: SCNNode) {
        // Add emission material for glow effect using viewModel
        if let geometry = node.geometry {
            for material in geometry.materials {
                viewModel.configureGlowEffect(for: material)
            }
        }
        
        // Recursively apply to child nodes
        for child in node.childNodes {
            addGlowEffect(to: child)
        }
    }
    
    private func setupPhysics() {
        // Use physics shape from viewModel
        let shape = viewModel.createPhysicsShape()
        physicsBody = SCNPhysicsBody(type: .static, shape: shape)
        physicsBody?.isAffectedByGravity = false
    }
    
    func startPulseAnimation() {
        pulseAction = viewModel.createPulseAnimation()
        starNode?.runAction(pulseAction!)
        viewModel.startAnimation()
    }
    
    func stopPulseAnimation() {
        starNode?.removeAllActions()
        viewModel.stopAnimation()
    }
    
    func updateMemory(_ memory: Memory) {
        viewModel.updateMemory(memory)
        let moveAction = viewModel.createMoveAnimation(to: viewModel.position)
        runAction(moveAction)
    }
    
    func highlightStar() {
        guard let material = starNode?.geometry?.firstMaterial else { return }
        
        let highlightAction = viewModel.createHighlightAnimation(for: material)
        starNode?.runAction(highlightAction)
        viewModel.setHighlighted(true)
        
        // Reset highlight state after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            self.viewModel.setHighlighted(false)
        }
    }
}