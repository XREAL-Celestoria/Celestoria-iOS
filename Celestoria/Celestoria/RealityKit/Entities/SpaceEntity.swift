//
//  SpaceEntity.swift
//  Celestoria
//
//  Created by Park Seyoung on 1/20/25.
//

import SwiftUI
import Combine
import RealityKit
import RealityKitContent


class SpaceEntity: Entity {
    // MARK: - Properties
    private weak var coordinator: SpaceCoordinator?
    private var starEntities: [MemoryStarEntity] = []
    private var isProcessingVideo = false
    
    // MARK: - Constants
    private enum Constants {
        static let positionRange: ClosedRange<Float> = -4...4
        static let defaultScale: Float = 1.0
    }
    
    // MARK: - Initialization
    init(coordinator: SpaceCoordinator) {
        self.coordinator = coordinator
        super.init()
        print("SpaceEntity: Initialized with coordinator")
        setupSpaceEnvironment()
    }
    
    required init() {
        fatalError("init() has not been implemented")
    }
    
    // MARK: - Setup Methods
    private func setupSpaceEnvironment() {
        addSpaceBackground()
    }
    
    private func addSpaceBackground() {
        let spaceBackground = SpaceBackgroundEntity()
        addChild(spaceBackground)
    }
    
    // MARK: - Star Management
    func updateStars(with memories: [Memory]) async {
        cleanupExistingContent()
        await createNewStars(from: memories)
        print("Star update completed. Total stars: \(starEntities.count)")
    }
    
    private func cleanupExistingContent() {
        removeExistingStars()
    }
    
    private func removeExistingStars() {
        starEntities.forEach { $0.removeFromParent() }
        starEntities.removeAll()
    }
    
    private func createNewStars(from memories: [Memory]) async {
        for memory in memories {
            let star = await createStar(for: memory)
            addChild(star)
            starEntities.append(star)
        }
    }
    
    private func createStar(for memory: Memory) async -> MemoryStarEntity {
        let position = generateRandomPosition()
        let star = MemoryStarEntity(memory: memory, position: position)
        
        await star.loadModel(for: memory.category)
        
        return star
    }
    
    private func generateRandomPosition() -> SIMD3<Float> {
        return SIMD3<Float>(
            Float.random(in: Constants.positionRange),
            Float.random(in: Constants.positionRange),
            Float.random(in: -6...1)
        )
    }
    
    private func findStarEntity(for memory: Memory) throws -> MemoryStarEntity {
        guard let starEntity = starEntities.first(where: { $0.memory.id == memory.id }) else {
            throw VideoError.starNotFound
        }
        return starEntity
    }
    
    private func getVideoURL(from memory: Memory) throws -> URL {
        guard let videoURLString = memory.videoURL,
              let videoURL = URL(string: videoURLString) else {
            throw VideoError.invalidURL
        }
        return videoURL
    }
}

// MARK: - Error Types
enum VideoError: Error {
    case invalidURL
    case processingInProgress
    case invalidEntity
    case starNotFound
    
    var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "Invalid video URL"
        case .processingInProgress:
            return "Video is currently being processed"
        case .invalidEntity:
            return "Invalid entity reference"
        case .starNotFound:
            return "Could not find the associated star entity"
        }
    }
}
