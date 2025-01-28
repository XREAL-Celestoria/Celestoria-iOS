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
    
    @Published var isLoading: Bool = false
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
        onCompletion()
        guard spaceEntity == nil else {
            onCompletion()
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            // SpaceEntity 초기화
            let backgroundImageName = appModel.selectedStarfield?.imageName ?? "Starfield-gray"
            let newSpaceEntity = SpaceEntity(coordinator: self, backgroundImageName: backgroundImageName)
            self.spaceEntity = newSpaceEntity
            os.Logger.info("SpaceCoordinator: Created SpaceEntity with background \(backgroundImageName)")

            // loadData 호출로 이 부분 필요 없음
            // 초기 별 로딩
            // let userId = appModel.userId ?? UUID()
            // let userMemories = try await memoryRepository.fetchMemories(for: userId)
            // memories = userMemories
            // await spaceEntity?.updateStars(with: userMemories) { [weak self] in
            //     os.Logger.info("SpaceCoordinator: Stars update completed for initialization")
            //     onCompletion() // 별 생성 완료 후 클로저 호출
            // }
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
            await spaceEntity?.updateStars(with: memories) {
                os.Logger.info("SpaceCoordinator: setInitialMemories - Stars updated for initial memories.")
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
        defer { isLoading = false }

        os.Logger.info("SpaceCoordinator: loadData(for \(userId)) called")

        do {
            // 1) 유저 프로필 조회
            let profile = try await profileUseCase.fetchProfileByUserId(userId: userId)
            let starfieldName = profile.starfield ?? "Starfield-gray"

            // 2) SpaceEntity 초기화 또는 배경 업데이트
            if spaceEntity == nil {
                spaceEntity = SpaceEntity(coordinator: self, backgroundImageName: starfieldName)
                os.Logger.info("SpaceCoordinator: Created new SpaceEntity for user \(userId)")
            } else {
                spaceEntity?.updateBackground(with: starfieldName)
            }

            // 3) 유저 메모리들 조회
            let userMemories = try await memoryRepository.fetchMemories(for: userId)
            memories = userMemories
            os.Logger.info("SpaceCoordinator: fetched \(userMemories.count) memories for user \(userId)")

            // 4) 별 업데이트
            isLoading = true
            await spaceEntity?.updateStars(with: userMemories) { [weak self] in
                Task { @MainActor in
                    self?.isLoading = false
                    os.Logger.info("SpaceCoordinator: Stars update completed for user \(userId)")
                }
            }

            self.currentLoadedUserId = userId
        } catch {
            os.Logger.error("SpaceCoordinator loadData(for: \(userId)) failed: \(error.localizedDescription)")
        }
    }
}
