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
    @Published private(set) var spaceEntity: SpaceEntity?
    @Published var memories: [Memory] = []

    init() {
        os.Logger.info("SpaceCoordinator: Initialized")
    }

    func initialize() {
        if spaceEntity == nil {
            spaceEntity = SpaceEntity(coordinator: self)
            os.Logger.info("SpaceCoordinator: Created new SpaceEntity")
        }
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
