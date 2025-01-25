//
//  SpaceCoordinator.swift
//  Celestoria
//
//  Created by Park Seyoung on 1/20/25.
//

import Combine
import RealityKit
import os

final class SpaceCoordinator: ObservableObject {
    private let appModel: AppModel
    @Published private(set) var spaceEntity: SpaceEntity?
    @Published var memories: [Memory] = []
    
    init(appModel: AppModel) {
        self.appModel = appModel
        os.Logger.info("SpaceCoordinator: Initialized")
    }
    
    @MainActor
    func initialize() {
        if spaceEntity == nil {
            let backgroundImageName = appModel.selectedStarfield?.imageName ?? appModel.randomBackground
            spaceEntity = SpaceEntity(coordinator: self, backgroundImageName: backgroundImageName)
            os.Logger.info("SpaceCoordinator: Created SpaceEntity with background \(backgroundImageName)")
        }
    }
    
    @MainActor
    func updateBackground(with imageName: String) {
        guard let spaceEntity = spaceEntity else {
            os.Logger.error("SpaceEntity is nil, cannot update background.")
            return
        }
        spaceEntity.updateBackground(with: imageName)
    }
    
    
    func setInitialMemories(_ newMemories: [Memory]) {
        memories = newMemories
        Task { @MainActor in
            await spaceEntity?.updateStars(with: memories)
        }
    }
    
    func handleNewMemory(_ memory: Memory) {
        guard !memories.contains(where: { $0.id == memory.id }) else {
            os.Logger.info("SpaceCoordinator: Memory already exists: \(memory.id)")
            return
        }
        
        memories.append(memory)
        os.Logger.info("SpaceCoordinator: Added new memory. Total count: \(self.memories.count)")
        Task { @MainActor in
            await spaceEntity?.updateStars(with: memories)
        }
    }
}
