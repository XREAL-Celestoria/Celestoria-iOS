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
import os

class SpaceEntity: Entity {
    // MARK: - Properties
    private weak var coordinator: SpaceCoordinator?
    private var starEntities: [MemoryStarEntity] = []
    private var isProcessingVideo = false
    private var backgroundEntity: SpaceBackgroundEntity? // 배경 엔티티 참조
    private let backgroundImageName: String

    // MARK: - Constants
    private enum Constants {
        static let positionRange: ClosedRange<Float> = -4...4
        static let defaultScale: Float = 1.0
    }

    // MARK: - Initialization
    init(coordinator: SpaceCoordinator? = nil, backgroundImageName: String) {
        self.coordinator = coordinator
        self.backgroundImageName = backgroundImageName
        super.init()
        setupSpaceEnvironment()
    }

    required init() {
        fatalError("init() has not been implemented")
    }

    // MARK: - Setup Methods
    private func setupSpaceEnvironment() {
        addSpaceBackground(imageName: backgroundImageName)
    }

    private func addSpaceBackground(imageName: String) {
        // 기존 배경 제거
        backgroundEntity?.removeFromParent()

        // 새로운 배경 엔티티 생성
        let spaceBackground = SpaceBackgroundEntity(backgroundImageName: imageName)
        addChild(spaceBackground)
        backgroundEntity = spaceBackground
    }

    // MARK: - Update Background
    func updateBackground(with imageName: String) {
        guard let backgroundEntity = backgroundEntity else {
            os.Logger.error("SpaceEntity: Background entity not found. Creating a new one.")
            addSpaceBackground(imageName: imageName)
            return
        }
        
        backgroundEntity.updateTexture(with: imageName)
        os.Logger.info("SpaceEntity: Background updated to \(imageName)")
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
    
    func removeStar(for memory: Memory) async {
        guard let starIndex = starEntities.firstIndex(where: { $0.memory.id == memory.id }) else {
            os.Logger.warning("SpaceEntity: No star found for Memory ID=\(memory.id)")
            return
        }
        
        let starToRemove = starEntities.remove(at: starIndex)
        starToRemove.removeFromParent()
        
        os.Logger.info("SpaceEntity: Removed star for Memory ID=\(memory.id). Remaining stars: \(starEntities.count)")
    }

    private func createNewStars(from memories: [Memory]) async {
        print("[DEBUG] Creating new stars for \(memories.count) memories.")
        for memory in memories {
            print("   → Memory ID=\(memory.id), title=\(memory.title), videoURL=\(memory.videoURL ?? "nil")")
            let star = await createStar(for: memory)
            addChild(star)
            starEntities.append(star)
        }
    }

    private func createStar(for memory: Memory) async -> MemoryStarEntity {
        // memory에 저장된 position을 SIMD3<Float>로 변환
        let position = SIMD3<Float>(
            Float(memory.position.x),
            Float(memory.position.y),
            Float(memory.position.z)
        )
        let star = MemoryStarEntity(memory: memory, position: position)

        await star.loadModel(for: memory.category)

        return star
    }
    
    func addStar(for memory: Memory) async {
        os.Logger.info("SpaceEntity: Adding a new star for Memory ID=\(memory.id)")
        
        let position = SIMD3<Float>(
            Float(memory.position.x),
            Float(memory.position.y),
            Float(memory.position.z)
        )
        
        let star = await createStar(for: memory)
        starEntities.append(star)
        addChild(star)
        
        os.Logger.info("SpaceEntity: Star added for Memory ID=\(memory.id). Total stars: \(starEntities.count)")
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

