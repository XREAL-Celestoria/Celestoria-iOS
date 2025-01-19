//
//  ConstellationSpaceEntity.swift
//  Celestoria
//
//  Created by Park Seyoung on 1/20/25.
//

import SwiftUI
import Combine
import RealityKit
import RealityKitContent

@MainActor
class ConstellationSpaceEntity: Entity {
//    // MARK: - Properties
//    private weak var coordinator: ConstellationSpaceCoordinator?
//    private var starEntities: [MemoryStarEntity] = []
//    private var isProcessingVideo = false
//    
//    // MARK: - Constants
//    private enum Constants {
//        static let positionRange: ClosedRange<Float> = -3...3
//        static let defaultScale: Float = 1.0
//    }
//    
//    // MARK: - Initialization
//    init(coordinator: ConstellationSpaceCoordinator) {
//        self.coordinator = coordinator
//        super.init()
//        print("constellationEntity: Initialized with coordinator")
//        setupSpaceEnvironment()
//    }
//    
//    required init() {
//        fatalError("init() has not been implemented")
//    }
//    
//    // MARK: - Setup Methods
//    private func setupSpaceEnvironment() {
//        addSpaceBackground()
//    }
//    
//    private func addSpaceBackground() {
//        let constellationBackground = ConstellationBackgroundEntity()
//        addChild(constellationBackground)
//    }
//    
//    // MARK: - Star Management
//    func updateStars(with memories: [Memory]) async {
//        await MainActor.run {
//            cleanupExistingContent()
//            createNewStars(from: memories)
//            print("Star update completed. Total stars: \(starEntities.count)")
//        }
//    }
//    
//    private func cleanupExistingContent() {
//        removeExistingStars()
//    }
//    
//    private func removeExistingStars() {
//        starEntities.forEach { $0.removeFromParent() }
//        starEntities.removeAll()
//    }
//    
//    private func createNewStars(from memories: [Memory]) {
//        for memory in memories {
//            let star = createStar(for: memory)
//            addChild(star)
//            starEntities.append(star)
//        }
//    }
//    
//    private func createStar(for memory: Memory) -> MemoryStarEntity {
//        let position = generateRandomPosition()
//        return MemoryStarEntity(memory: memory, position: position)
//    }
//    
//    private func generateRandomPosition() -> SIMD3<Float> {
//        return SIMD3<Float>(
//            Float.random(in: Constants.positionRange),
//            Float.random(in: Constants.positionRange),
//            Float.random(in: Constants.positionRange)
//        )
//    }
//    
//    private func findStarEntity(for memory: Memory) throws -> MemoryStarEntity {
//        guard let starEntity = starEntities.first(where: { $0.memory.id == memory.id }) else {
//            throw VideoError.starNotFound
//        }
//        return starEntity
//    }
//    
//    private func getVideoURL(from memory: Memory) throws -> URL {
//        guard let videoURLString = memory.videoURL,
//              let videoURL = URL(string: videoURLString) else {
//            throw VideoError.invalidURL
//        }
//        return videoURL
//    }
}
