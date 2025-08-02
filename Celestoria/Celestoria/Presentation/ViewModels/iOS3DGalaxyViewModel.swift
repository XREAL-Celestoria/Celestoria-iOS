//
//  iOS3DGalaxyViewModel.swift
//  Celestoria
//
//  Created by Minjun Kim on 7/20/25.
//

import SwiftUI
import SceneKit
import os

@MainActor
class iOS3DGalaxyViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var selectedMemory: Memory?
    @Published var showMemoryDetail = false
    @Published var isContentReady = false
    
    // MARK: - Scene Properties
    var scene: SCNScene?
    var backgroundNode: SCNNode?
    var cameraNode: SCNNode?
    var memoryNodes: [UUID: iOS3DMemoryStarNode] = [:]
    
    // MARK: - Dependencies
    private let galaxyViewModel: GalaxyViewModel
    private let appState: AppState
    let diContainer: DIContainer
    
    // MARK: - Constants
    private enum Constants {
        static let cameraFieldOfView: CGFloat = 60
        static let cameraZNear: CGFloat = 0.1
        static let cameraZFar: CGFloat = 2000
        static let cameraPosition = SCNVector3(x: 0, y: 0, z: 5)
        static let skyboxRadius: CGFloat = 1000
        static let skyboxSegments = 48
        static let ambientLightIntensity: CGFloat = 0.3
    }
    
    // MARK: - Initialization
    init(galaxyViewModel: GalaxyViewModel, appState: AppState, diContainer: DIContainer) {
        self.galaxyViewModel = galaxyViewModel
        self.appState = appState
        self.diContainer = diContainer
        
        setupContentReady()
    }
    
    // MARK: - Public Methods
    func setupScene(_ scene: SCNScene) {
        self.scene = scene
        setupCamera(in: scene)
        setupLighting(in: scene)
        setupBackground(in: scene)
    }
    
    func loadMemories() {
        Task {
            do {
                if let targetUserId = appState.galaxyTargetUserId,
                   targetUserId != appState.currentUserId {
                    try await galaxyViewModel.fetchMemoriesFromOtherUser(userId: targetUserId)
                } else {
                    try await galaxyViewModel.fetchCurrentUserMemories()
                }
                
                updateMemoryNodes()
            } catch {
                Logger.error("Error loading memories: \(error.localizedDescription)")
            }
        }
    }
    
    func updateMemories() {
        updateMemoryNodes()
        updateBackground()
    }
    
    func handleMemorySelection(_ memory: Memory) {
        selectedMemory = memory
        showMemoryDetail = true
    }
    
    func clearSelectedMemory() {
        selectedMemory = nil
    }
    
    // MARK: - Private Methods
    private func setupContentReady() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.easeIn(duration: 0.3)) {
                self.isContentReady = true
            }
        }
    }
    
    private func setupCamera(in scene: SCNScene) {
        let camera = SCNCamera()
        camera.fieldOfView = Constants.cameraFieldOfView
        camera.zNear = Constants.cameraZNear
        camera.zFar = Constants.cameraZFar
        
        cameraNode = SCNNode()
        cameraNode?.camera = camera
        cameraNode?.position = Constants.cameraPosition
        scene.rootNode.addChildNode(cameraNode!)
    }
    
    private func setupLighting(in scene: SCNScene) {
        let ambientLight = SCNLight()
        ambientLight.type = .ambient
        ambientLight.color = UIColor(white: Constants.ambientLightIntensity, alpha: 1.0)
        
        let ambientNode = SCNNode()
        ambientNode.light = ambientLight
        scene.rootNode.addChildNode(ambientNode)
    }
    
    private func setupBackground(in scene: SCNScene) {
        let sphere = SCNSphere(radius: Constants.skyboxRadius)
        sphere.segmentCount = Constants.skyboxSegments
        
        let material = SCNMaterial()
        material.lightingModel = .constant
        material.isDoubleSided = true
        material.cullMode = .front
        
        let starfieldName = getStarfieldName()
        if let starfieldImage = UIImage(named: starfieldName) {
            material.diffuse.contents = starfieldImage
            Logger.info("Initial background set to: \(starfieldName)")
        } else {
            Logger.warning("Failed to load starfield image: \(starfieldName), using default")
            material.diffuse.contents = UIImage(named: "Starfield-1")
        }
        
        sphere.materials = [material]
        
        backgroundNode = SCNNode(geometry: sphere)
        scene.rootNode.addChildNode(backgroundNode!)
    }
    
    private func updateMemoryNodes() {
        guard let scene = scene else { return }
        
        let currentMemoryIds = Set(galaxyViewModel.memories.map { $0.id })
        let existingMemoryIds = Set(memoryNodes.keys)
        
        // Remove old nodes
        let toRemove = existingMemoryIds.subtracting(currentMemoryIds)
        for id in toRemove {
            memoryNodes[id]?.removeFromParentNode()
            memoryNodes.removeValue(forKey: id)
        }
        
        // Add new nodes and update existing ones
        for memory in galaxyViewModel.memories {
            if memoryNodes[memory.id] == nil {
                let node = iOS3DMemoryStarNode(memory: memory)
                scene.rootNode.addChildNode(node)
                memoryNodes[memory.id] = node
                node.startPulseAnimation()
            } else if let node = memoryNodes[memory.id] {
                node.updateMemory(memory)
            }
        }
    }
    
    private func updateBackground() {
        guard let material = backgroundNode?.geometry?.firstMaterial else { 
            Logger.warning("Background node or material is not initialized yet")
            return
        }
        
        let starfieldName = getStarfieldName()
        if let backgroundImage = UIImage(named: starfieldName) {
            material.diffuse.contents = backgroundImage
            Logger.info("Background updated with: \(starfieldName)")
        } else {
            Logger.warning("Failed to load starfield image: \(starfieldName), using default")
            material.diffuse.contents = UIImage(named: "Starfield-1")
        }
    }
    
    private func getStarfieldName() -> String {
        if let selected = galaxyViewModel.selectedImage {
            return selected
        } else {
            let starfieldCount = 18
            let randomIndex = Int.random(in: 1...starfieldCount)
            return "Starfield-\(randomIndex)"
        }
    }
} 
