//
//  UserInfoModalViewModel.swift
//  Celestoria
//
//  Created by Minjun Kim on 7/20/25.
//

import Foundation
import SwiftUI
import os

@MainActor
class UserInfoModalViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var userProfile: UserProfile?
    @Published var memoryCount: Int = 0
    @Published var followerCount: Int = 0 // TODO: Implement followers when available
    @Published var commentCount: Int = 0 // Comments feature not implemented yet
    @Published var likeCount: Int = 0
    
    // MARK: - UI State Properties
    @Published var isExpanded: Bool = false
    @Published var dragOffset: CGFloat = 0
    @Published var isLoading: Bool = false
    @Published var sortOption: SortOption = .latest
    @Published var selectedMemory: Memory?
    
    // MARK: - Real Data for Expanded Content
    @Published var memories: [Memory] = []
    
    // MARK: - Dependencies
    private let diContainer: DIContainer
    private let userId: UUID
    private let appState: AppState
    private let memoryRepository: MemoryRepository
    
    // MARK: - Enums
    enum SortOption: String, CaseIterable {
        case latest = "Latest"
        case oldest = "Oldest"
        
        var displayName: String { rawValue }
    }
    
    // MARK: - Initialization
    init(diContainer: DIContainer, userId: UUID) {
        self.diContainer = diContainer
        self.userId = userId
        self.appState = diContainer.appState
        self.memoryRepository = diContainer.memoryRepository
        
        Logger.info("UserInfoModalViewModel: Initialized for userId: \(userId)")
        
        loadUserData()
        setupRefreshObserver()
    }
    
    // MARK: - Public Methods
    func loadUserData() {
        isLoading = true
        Task {
            await loadUserProfile()
            await loadUserStats()
            await loadMemories()
            isLoading = false
        }
    }
    
    // MARK: - UI State Management
    func toggleExpanded() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            isExpanded.toggle()
            if !isExpanded {
                dragOffset = 0
            }
        }
    }
    
    func handleDragChanged(_ value: DragGesture.Value) {
        if isExpanded {
            // 확장된 상태에서는 아래로 드래그만 허용 (축소)
            if value.translation.height > 0 {
                dragOffset = value.translation.height * 0.3
            }
        } else {
            // 축소된 상태에서는 위로 드래그만 허용 (확장)
            if value.translation.height < 0 {
                dragOffset = value.translation.height * 0.3
            }
        }
    }
    
    func handleDragEnded(_ value: DragGesture.Value) {
        if isExpanded {
            // 확장된 상태에서 아래로 충분히 드래그하면 축소
            if value.translation.height > 100 {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    isExpanded = false
                    dragOffset = 0
                }
            } else {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    dragOffset = 0
                }
            }
        } else {
            // 축소된 상태에서 위로 충분히 드래그하면 확장
            if value.translation.height < -60 {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    isExpanded = true
                    dragOffset = 0
                }
            } else {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    dragOffset = 0
                }
            }
        }
    }
    
    func expandModal() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            isExpanded = true
            dragOffset = 0
        }
    }
    
    func closeModal() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            isExpanded = false
            dragOffset = 0
        }
    }
    
    func changeSortOption(_ newOption: SortOption) {
        sortOption = newOption
        // Sort the memories based on the new option
        sortMemories()
    }
    
    func refreshProfileData() {
        Logger.info("UserInfoModalViewModel: Manual profile refresh requested")
        Task {
            await reloadUserProfile()
            // 통계도 함께 업데이트
            await loadUserStats()
        }
    }
    
    // MARK: - Memory Loading
    private func loadMemories() async {
        do {
            let fetchedMemories = try await memoryRepository.fetchMemories(for: userId)
            await MainActor.run {
                self.memories = fetchedMemories
                self.memoryCount = fetchedMemories.count
                self.sortMemories()
            }
            Logger.info("UserInfoModalViewModel: Loaded \(fetchedMemories.count) memories for user \(userId)")
        } catch {
            Logger.error("UserInfoModalViewModel: Failed to load memories - \(error.localizedDescription)")
        }
    }
    
    private func sortMemories() {
        switch sortOption {
        case .latest:
            memories.sort { $0.createdAt > $1.createdAt }
        case .oldest:
            memories.sort { $0.createdAt < $1.createdAt }
        }
    }
    
    // MARK: - Private Methods
    private func loadUserProfile() async {
        do {
            userProfile = try await diContainer.profileUseCase.fetchProfileByUserId(userId: userId)
            
            // 프로필 이미지 미리 로딩
            if let profileImageURL = userProfile?.profileImageURL {
                Task {
                    await ImageCache.shared.preloadProfileImage(urlString: profileImageURL)
                }
            }
        } catch {
            Logger.error("Error loading user profile: \(error.localizedDescription)")
        }
    }
    
    private func loadUserStats() async {
        do {
            // Load memories to get count and calculate total likes
            let memories = try await diContainer.memoryUseCase.execute(for: userId)
            memoryCount = memories.count
            
            // Calculate total likes across all user's memories
            var totalLikes = 0
            for memory in memories {
                let likeCount = try await diContainer.memoryRepository.getLikeCount(for: memory.id)
                totalLikes += likeCount
            }
            likeCount = totalLikes
            
            // Comments are not implemented yet, so always 0
            commentCount = 0
            
        } catch {
            Logger.error("Error loading user stats: \(error.localizedDescription)")
            memoryCount = 0
            likeCount = 0
            commentCount = 0
        }
    }
    
    private func setupRefreshObserver() {
        // appState.refreshMainView가 변경될 때마다 데이터 리프레시
        Task {
            for await refreshState in appState.$refreshMainView.values {
                if refreshState {
                    await loadUserData()
                    // 리프레시 완료 후 상태 리셋 - 다른 옵저버들이 처리할 시간을 주기 위해 약간의 지연 추가
                    try? await Task.sleep(nanoseconds: 100_000_000) // 0.1초 지연
                    appState.refreshMainView = false
                }
            }
        }
        
        // appState.userProfile이 변경될 때마다 현재 사용자의 프로필 업데이트
        Task {
            for await newProfile in appState.$userProfile.values {
                Logger.info("UserInfoModalViewModel: AppState userProfile changed - newProfile: \(newProfile?.name ?? "nil"), userId: \(newProfile?.userId ?? UUID()), current userId: \(userId)")
                
                // 현재 사용자의 프로필이 변경된 경우에만 업데이트
                if let newProfile = newProfile, newProfile.userId == userId {
                    let hasChanged = userProfile?.name != newProfile.name || 
                                   userProfile?.profileImageURL != newProfile.profileImageURL ||
                                   userProfile?.profileKey != newProfile.profileKey ||
                                   userProfile?.spaceThumbnailId != newProfile.spaceThumbnailId
                    
                    if hasChanged {
                        userProfile = newProfile
                        Logger.info("UserInfoModalViewModel: Profile updated for current user - name: \(newProfile.name), imageURL: \(newProfile.profileImageURL ?? "nil"), thumbnailId: \(newProfile.spaceThumbnailId ?? "nil")")
                        // 프로필이 업데이트되면 통계도 다시 로드
                        await loadUserStats()
                    }
                } else {
                    Logger.info("UserInfoModalViewModel: Profile not updated - userId mismatch or nil profile")
                }
            }
        }
    }
    
    private func reloadUserProfile() async {
        do {
            let freshProfile = try await diContainer.profileUseCase.fetchProfileByUserId(userId: userId)
            
            let hasChanged = userProfile?.name != freshProfile.name || 
                           userProfile?.profileImageURL != freshProfile.profileImageURL ||
                           userProfile?.profileKey != freshProfile.profileKey ||
                           userProfile?.spaceThumbnailId != freshProfile.spaceThumbnailId
            
            if hasChanged {
                userProfile = freshProfile
                Logger.info("UserInfoModalViewModel: Profile reloaded - name: \(freshProfile.name), imageURL: \(freshProfile.profileImageURL ?? "nil"), thumbnailId: \(freshProfile.spaceThumbnailId ?? "nil")")
                
                // 프로필 이미지 미리 로딩
                if let profileImageURL = freshProfile.profileImageURL {
                    Task {
                        await ImageCache.shared.preloadProfileImage(urlString: profileImageURL)
                    }
                }
            }
        } catch {
            Logger.error("UserInfoModalViewModel: Failed to reload user profile: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Memory Selection
    func selectMemory(_ memory: Memory) {
        selectedMemory = memory
        Logger.info("UserInfoModalViewModel: Memory selected - ID: \(memory.id), Title: \(memory.title)")
    }
} 
