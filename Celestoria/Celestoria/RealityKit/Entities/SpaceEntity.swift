//
//  SpaceEntity.swift
//  Celestoria
//
//  Created by Park Seyoung on 1/20/25.
//

import SwiftUI
import RealityKit
import os

/// 3D 공간을 나타내는 엔티티
class SpaceEntity: Entity {
    private let backgroundManager = BackgroundManager()
    private let logger = Logger(subsystem: "Celestoria", category: "SpaceEntity")
    private var starEntities: [MemoryStarEntity] = []
    
    // MARK: - Constants
    private enum Constants {
        static let positionRange: ClosedRange<Float> = -3...3
    }
    
    // MARK: - Initialization
    init(backgroundImageName: String) {
        super.init()
        setupSpace(with: backgroundImageName)
    }
    
    required init() {
        super.init()
        // 기본 배경으로 초기화
        setupSpace(with: "Starfield-1")
    }
    
    // MARK: - Setup
    private func setupSpace(with backgroundImageName: String) {
        backgroundManager.setupBackground(imageName: backgroundImageName, in: self)
    }
    
    // MARK: - Public Methods
    
    func updateBackground(with imageName: String) {
        backgroundManager.updateBackground(imageName: imageName)
    }
    
    // MARK: - Star Management
    
    /// Updates all stars based on the provided memories
    func updateStars(with memories: [Memory]) async {
        // Remove existing stars
        cleanupExistingStars()
        
        // Create new stars
        for memory in memories {
            await addStar(for: memory)
        }
        
        logger.info("Updated stars. Total: \(self.starEntities.count)")
    }
    
    /// Adds a single star for a memory
    func addStar(for memory: Memory) async {
        // Check if star already exists
        if self.starEntities.contains(where: { $0.memory.id == memory.id }) {
            logger.info("Star already exists for memory: \(memory.id)")
            return
        }
        
        let star = await createStar(for: memory)
        addChild(star)
        starEntities.append(star)
        
        logger.info("Added star for memory: \(memory.id)")
    }
    
    /// Removes a star for the given memory ID
    func removeStar(for memoryId: UUID) {
        guard let index = self.starEntities.firstIndex(where: { $0.memory.id == memoryId }) else {
            logger.warning("No star found for memory ID: \(memoryId)")
            return
        }
        
        let star = starEntities.remove(at: index)
        star.removeFromParent()
        
        logger.info("Removed star for memory ID: \(memoryId)")
    }
    
    // MARK: - Private Methods
    
    private func cleanupExistingStars() {
        starEntities.forEach { $0.removeFromParent() }
        starEntities.removeAll()
    }
    
    private func createStar(for memory: Memory) async -> MemoryStarEntity {
        let position: SIMD3<Float>
        
        // Use stored position if available, otherwise generate random position
        if memory.position.x == 0 && memory.position.y == 0 && memory.position.z == 0 {
            // Generate random position
            position = generateRandomPosition()
        } else {
            // Use stored position
            position = SIMD3<Float>(
                Float(memory.position.x),
                Float(memory.position.y),
                Float(memory.position.z)
            )
        }
        
        let star = MemoryStarEntity(memory: memory, position: position)
        
        // Load 3D model based on category
        await star.loadModel(for: memory.category)
        
        // Add directional light
        let light = createDirectionalLight()
        star.addChild(light)
        
        return star
    }
    
    private func generateRandomPosition() -> SIMD3<Float> {
        return SIMD3<Float>(
            Float.random(in: Constants.positionRange),
            Float.random(in: Constants.positionRange),
            Float.random(in: Constants.positionRange)
        )
    }
    
    private func createDirectionalLight() -> Entity {
        let lightEntity = Entity()
        
        var lightComponent = DirectionalLightComponent()
        lightComponent.intensity = 2000
        lightComponent.color = .white
        
        lightEntity.components[DirectionalLightComponent.self] = lightComponent
        lightEntity.look(at: [0, 0, 0], from: [1, 1, 1], relativeTo: nil)
        
        return lightEntity
    }
}

