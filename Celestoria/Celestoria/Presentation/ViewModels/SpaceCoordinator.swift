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
    
    // 좋아요 애니메이션을 위한 프로퍼티
    private var fireworksEntity: Entity?
    private let headAnchor = AnchorEntity(.head)
    
    private let logger = Logger(subsystem: "Celestoria", category: "SpaceCoordinator")
    
    init(memoryRepository: MemoryRepository,
         profileUseCase: ProfileUseCase,
         appState: AppState? = nil) {
        self.memoryRepository = memoryRepository
        self.profileUseCase = profileUseCase
        self.appState = appState
        
        // 미리 'fireworks' 에셋을 로드합니다.
        Task {
            await self.loadFireworksEntity()
        }
    }
    
    // MARK: - Public Methods
    
    /// 공간을 초기화합니다
    func initialize() async {
        guard spaceEntity == nil else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        let backgroundImageName = appState?.selectedStarfield?.imageName ?? "Starfield-1"
        spaceEntity = SpaceEntity(backgroundImageName: backgroundImageName)
        
        // 사용자의 머리를 추적하는 앵커를 spaceEntity에 추가합니다.
        spaceEntity?.addChild(headAnchor)
        
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
                // 사용자의 머리를 추적하는 앵커를 spaceEntity에 추가합니다.
                spaceEntity?.addChild(headAnchor)
            } else {
                spaceEntity?.updateBackground(with: starfieldName)
            }
            
            // 메모리 로드
            let userMemories = try await memoryRepository.fetchMemories(for: userId)
            self.memories = userMemories
            await spaceEntity?.updateStars(with: userMemories)
            
            currentLoadedUserId = userId
        } catch {
            logger.error("❌ loadData failed: \(error.localizedDescription)")
        }
    }
    
    /// 초기 메모리를 설정합니다
    func setInitialMemories(_ newMemories: [Memory]) async {
        isLoading = true
        defer { isLoading = false }
        
        self.memories = newMemories
        await spaceEntity?.updateStars(with: self.memories)
    }
    
    // MARK: - Like Animation
    
    @MainActor
    private func loadFireworksEntity() async {
        guard fireworksEntity == nil else { return }
        do {
            let loadedEntity = try await Entity(named: "fireworks")
            // 파티클 효과를 내는 실제 자식 엔티티를 찾아서 저장합니다.
            if let particleEmitter = loadedEntity.children.first?.children.first {
                self.fireworksEntity = particleEmitter
                logger.info("✅ 'fireworks' particle emitter pre-loaded and stored.")
            } else {
                logger.error("❌ Could not find the particle emitter in 'fireworks'.")
            }
        } catch {
            logger.error("❌ Failed to pre-load 'fireworks' entity: \(error.localizedDescription)")
        }
    }
    
    @MainActor
    func playLikeAnimation() {
        logger.info("playLikeAnimation() called.")
        
        guard let fireworks = self.fireworksEntity else {
            logger.error("❌ Cannot play like animation: fireworksEntity is not loaded.")
            return
        }
        
        Task {
            let entity = fireworks.clone(recursive: true)
            let scaleFactor: Float = 0.3 // 스케일 조정 비율

            // 파티클 시스템의 속성을 직접 수정하여 크기를 조절합니다.
            if var particleEmitter = entity.components[ParticleEmitterComponent.self] {
                // 파티클 크기 조정
                particleEmitter.mainEmitter.size *= scaleFactor
                
                entity.components.set(particleEmitter)
                logger.info("✅ Particle system properties scaled by \(scaleFactor).")
            } else {
                logger.warning("⚠️ Could not find ParticleEmitterComponent to scale. Using entity.setScale as fallback.")
                // 파티클 컴포넌트를 찾지 못하더라도, 이전 방식으로 스케일을 시도합니다.
                entity.setScale(SIMD3<Float>(repeating: scaleFactor), relativeTo: nil)
            }
            
            // 위치를 머리 앵커 기준으로 설정합니다.
            entity.position = [0, 0, -0.1] // 시선 중앙 10cm 앞

            headAnchor.addChild(entity)
            logger.info("✅ Heart animation added to headAnchor.")

            try await Task.sleep(for: .seconds(3))

            headAnchor.removeChild(entity)
            logger.info("✅ Heart animation removed from headAnchor.")
        }
    }
}
