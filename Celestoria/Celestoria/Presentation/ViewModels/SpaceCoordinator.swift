//
//  SpaceCoordinator.swift
//  Celestoria
//
//  Created by Park Seyoung on 1/20/25.
//

import Combine
import RealityKit
import os
import Foundation

final class SpaceCoordinator: ObservableObject {
    private let appModel: AppModel
    private let memoryRepository: MemoryRepository
    private let profileUseCase: ProfileUseCase

    @Published private(set) var spaceEntity: SpaceEntity?
    @Published var memories: [Memory] = []

    private(set) var currentLoadedUserId: UUID? = nil
    
    init(appModel: AppModel,
         memoryRepository: MemoryRepository,
         profileUseCase: ProfileUseCase) {
        self.appModel = appModel
        self.memoryRepository = memoryRepository
        self.profileUseCase = profileUseCase
        os.Logger.info("SpaceCoordinator: Initialized")
    }
    
    /// 앱 첫 실행 시 불리는 함수 (내 우주 초기화)
    @MainActor
    func initialize() {
        // 이미 있으면 재생성 안 함
        guard spaceEntity == nil else { return }

        let backgroundImageName = appModel.selectedStarfield?.imageName ?? "Starfield-gray"
        spaceEntity = SpaceEntity(coordinator: self, backgroundImageName: backgroundImageName)
        os.Logger.info("SpaceCoordinator: Created SpaceEntity with background \(backgroundImageName)")
    }
    
    @MainActor
    func updateBackground(with imageName: String) {
        guard let spaceEntity = spaceEntity else {
            os.Logger.error("SpaceEntity is nil, cannot update background.")
            return
        }
        spaceEntity.updateBackground(with: imageName)
    }
    
    @MainActor
    func removeMemoryStar(with memoryID: UUID) {
        if let index = memories.firstIndex(where: { $0.id == memoryID }) {
            let removedMemory = memories.remove(at: index)
            os.Logger.info("SpaceCoordinator: Removed memory star for memory ID: \(memoryID)")
            
            Task { @MainActor in
                await spaceEntity?.removeStar(for: removedMemory)
            }
        } else {
            os.Logger.warning("SpaceCoordinator: Memory star with ID \(memoryID) not found.")
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
            await spaceEntity?.addStar(for: memory)
        }
    }

    /// 유저 ID를 받아서, 그 유저 우주(배경 + 메모리)로 전환
    @MainActor
    func loadData(for userId: UUID) async {
        os.Logger.info("SpaceCoordinator: loadData(for \(userId)) called")

        do {
            // 1) 유저 프로필 조회
            let profile = try await profileUseCase.fetchProfileByUserId(userId: userId)
            let starfieldName = profile.starfield ?? "Starfield-gray"
            
            // 2) spaceEntity가 없으면 만들고, 있으면 배경만 업데이트
            if spaceEntity == nil {
                spaceEntity = SpaceEntity(coordinator: self, backgroundImageName: starfieldName)
                os.Logger.info("SpaceCoordinator: Created new SpaceEntity for user \(userId)")
            } else {
                spaceEntity?.updateBackground(with: starfieldName)
                os.Logger.info("SpaceCoordinator: Updated background to \(starfieldName) for user \(userId)")
            }

            // 3) 해당 유저 메모리들 불러오기
            let userMemories = try await memoryRepository.fetchMemories(for: userId)
            memories = userMemories
            os.Logger.info("SpaceCoordinator: fetched \(userMemories.count) memories for user \(userId)")

            // 4) 별(Star) 업데이트
            await spaceEntity?.updateStars(with: userMemories)
            os.Logger.info("SpaceCoordinator: updated stars. total = \(userMemories.count)")

            self.currentLoadedUserId = userId
        } catch {
            os.Logger.error("SpaceCoordinator loadData(for: \(userId)) failed: \(error.localizedDescription)")
        }
    }

}
