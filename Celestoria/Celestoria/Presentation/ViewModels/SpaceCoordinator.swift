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
    
    @Published var isLoading: Bool = true
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
    func initialize(onCompletion: @escaping () -> Void = {}) async {
        isLoading = true
        guard spaceEntity == nil else {
            isLoading = false
            onCompletion()
            return
        }
        do {
            // SpaceEntity 초기화
            let backgroundImageName = appModel.selectedStarfield?.imageName ?? "Starfield-gray"
            let newSpaceEntity = SpaceEntity(coordinator: self, backgroundImageName: backgroundImageName)
            self.spaceEntity = newSpaceEntity
            os.Logger.info("SpaceCoordinator: Created SpaceEntity with background \(backgroundImageName)")
            onCompletion() // 별 생성 완료 후 클로저 호출
        } catch {
            os.Logger.error("SpaceCoordinator initialize failed: \(error.localizedDescription)")
            onCompletion() // 에러 발생 시에도 호출
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
    
    func setInitialMemories(_ newMemories: [Memory], onCompletion: @escaping () -> Void = {}) {
        memories = newMemories
        Task { @MainActor in
            isLoading = true
            defer { isLoading = false }
            await spaceEntity?.updateStars(with: memories) {
                os.Logger.info("Stars updated for initial memories.")
                onCompletion()
            }
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
        isLoading = true
        defer { isLoading = false }  // 이 함수 리턴 직전에 무조건 false로
        
        os.Logger.info("loadData(for: \(userId)) called")

        do {
            let profile = try await profileUseCase.fetchProfileByUserId(userId: userId)
            let starfieldName = profile.starfield ?? "Starfield-gray"

            if spaceEntity == nil {
                spaceEntity = SpaceEntity(coordinator: self, backgroundImageName: starfieldName)
            } else {
                spaceEntity?.updateBackground(with: starfieldName)
            }

            let userMemories = try await memoryRepository.fetchMemories(for: userId)
            memories = userMemories

            // updateStars는 completion 받는다고 해도, 여기서 기다려도 좋음
            await spaceEntity?.updateStars(with: userMemories) {
                os.Logger.info("Stars update completed for user \(userId)")
            }

            self.currentLoadedUserId = userId

        } catch {
            // defer가 있기 때문에 여기서도 직접 끌 필요가 없음
            os.Logger.error("loadData(for: \(userId)) failed: \(error.localizedDescription)")
        }
    }

}
