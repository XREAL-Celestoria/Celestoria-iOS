//
//  SpaceCoordinator.swift
//  Celestoria
//
//  Created by Park Seyoung on 1/20/25.
//

import SwiftUI
import RealityKit
import os

/// 3D 공간과 메모리 상태를 조정하는 코디네이터
@MainActor
final class SpaceCoordinator: ObservableObject {
    // Dependencies
    private let memoryRepository: MemoryRepository
    private let profileUseCase: ProfileUseCase
    weak var appState: AppState?
    
    // State
    @Published var isLoading = false
    @Published private(set) var spaceEntity: SpaceEntity?
    @Published var memories: [Memory] = []
    private(set) var currentLoadedUserId: UUID?
    
    private let logger = Logger(subsystem: "Celestoria", category: "SpaceCoordinator")
    
    init(memoryRepository: MemoryRepository,
         profileUseCase: ProfileUseCase,
         appState: AppState? = nil) {
        self.memoryRepository = memoryRepository
        self.profileUseCase = profileUseCase
        self.appState = appState
    }
    
    // MARK: - Public Methods
    
    /// 공간을 초기화합니다
    func initialize() async {
        guard spaceEntity == nil else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        let backgroundImageName = appState?.selectedStarfield?.imageName ?? "Starfield-1"
        spaceEntity = SpaceEntity(backgroundImageName: backgroundImageName)
        logger.info("Initialized with background: \(backgroundImageName)")
    }
    
    /// 배경을 업데이트합니다
    func updateBackground(with imageName: String) {
        spaceEntity?.updateBackground(with: imageName)
    }
    
    /// 메모리를 추가합니다
    func handleNewMemory(_ memory: Memory) {
        guard !memories.contains(where: { $0.id == memory.id }) else {
            logger.info("Memory already exists: \(memory.id)")
            return
        }
        
        memories.append(memory)
        
        // Add star to the 3D space
        Task {
            await spaceEntity?.addStar(for: memory)
        }
    }
    
    /// 메모리를 제거합니다
    func removeMemory(id: UUID) {
        guard let index = memories.firstIndex(where: { $0.id == id }) else {
            logger.warning("Memory not found: \(id)")
            return
        }
        
        memories.remove(at: index)
        spaceEntity?.removeStar(for: id)
    }
    
    /// 특정 사용자의 데이터를 로드합니다
    func loadData(for userId: UUID) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // 프로필 로드
            let profile = try await profileUseCase.fetchProfileByUserId(userId: userId)
            let starfieldName = profile.starfield ?? "Starfield-1"
            
            // 공간 설정
            if spaceEntity == nil {
                spaceEntity = SpaceEntity(backgroundImageName: starfieldName)
            } else {
                spaceEntity?.updateBackground(with: starfieldName)
            }
            
            // 메모리 로드
            let userMemories = try await memoryRepository.fetchMemories(for: userId)
            memories = userMemories
            await spaceEntity?.updateStars(with: userMemories)
            
            currentLoadedUserId = userId
            logger.info("Loaded data for user: \(userId)")
            
        } catch {
            logger.error("Failed to load data: \(error.localizedDescription)")
        }
    }
    
    /// 초기 메모리를 설정합니다
    func setInitialMemories(_ newMemories: [Memory]) async {
        isLoading = true
        defer { isLoading = false }
        
        memories = newMemories
        await spaceEntity?.updateStars(with: memories)
    }
}
