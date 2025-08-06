//
//  UserInfoModalViewModel.swift
//  Celestoria
//
//  Created by Minjun Kim on 7/20/25.
//

import Foundation
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
    
    // MARK: - Mock Data for Expanded Content
    @Published var mockMemories: [MockMemory] = []
    
    // MARK: - Dependencies
    private let diContainer: DIContainer
    private let userId: UUID
    private let appState: AppState
    
    // MARK: - Enums
    enum SortOption: String, CaseIterable {
        case latest = "Latest"
        case oldest = "Oldest"
        case popular = "Popular"
        
        var displayName: String { rawValue }
    }
    
    struct MockMemory: Identifiable {
        let id = UUID()
        let title: String
        let views: Int
        let daysAgo: Int
        let duration: String
    }
    
    // MARK: - Initialization
    init(diContainer: DIContainer, userId: UUID) {
        self.diContainer = diContainer
        self.userId = userId
        self.appState = diContainer.appState
        
        Logger.info("UserInfoModalViewModel: Initialized for userId: \(userId)")
        
        generateMockMemories()
        loadUserData()
        setupRefreshObserver()
    }
    
    // MARK: - Public Methods
    func loadUserData() {
        isLoading = true
        Task {
            await loadUserProfile()
            await loadUserStats()
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
        if value.translation.height < 0 {
            dragOffset = value.translation.height * 0.3
        }
    }
    
    func handleDragEnded(_ value: DragGesture.Value) {
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
    
    func closeModal() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            isExpanded = false
        }
    }
    
    func changeSortOption(_ newOption: SortOption) {
        sortOption = newOption
        // Here you would typically resort the data based on the new option
        // For now, we'll just regenerate mock data
        generateMockMemories()
    }
    
    func refreshProfileData() {
        Logger.info("UserInfoModalViewModel: Manual profile refresh requested")
        Task {
            await reloadUserProfile()
            // 통계도 함께 업데이트
            await loadUserStats()
        }
    }
    
    // MARK: - Mock Data Generation
    private func generateMockMemories() {
        let durations = ["0:15", "0:32", "1:05", "0:48", "2:12", "0:23", "1:34", "0:56", "1:18", "0:41"]
        mockMemories = (1...10).map { index in
            MockMemory(
                title: "Memory \(index)",
                views: Int.random(in: 10...100),
                daysAgo: Int.random(in: 1...7),
                duration: durations.randomElement() ?? "0:30"
            )
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
        
        // appState.userProfile이 변경될 때마다 프로필 업데이트 체크
        Task {
            for await newProfile in appState.$userProfile.values {
                Logger.info("UserInfoModalViewModel: AppState userProfile changed - newProfile: \(newProfile?.name ?? "nil"), userId: \(newProfile?.userId ?? UUID()), current userId: \(userId)")
                
                await handleProfileUpdate(newProfile)
            }
        }
        
        // 정기적으로 프로필 업데이트 체크 (30초마다)
        Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 30_000_000_000) // 30초 대기
                await checkForProfileUpdates()
            }
        }
    }
    
    private func handleProfileUpdate(_ newProfile: UserProfile?) async {
        // 현재 관찰 중인 사용자의 프로필이 변경된 경우
        if let newProfile = newProfile, newProfile.userId == userId {
            let hasChanged = userProfile?.name != newProfile.name || 
                           userProfile?.profileImageURL != newProfile.profileImageURL ||
                           userProfile?.profileKey != newProfile.profileKey
            
            if hasChanged {
                userProfile = newProfile
                Logger.info("UserInfoModalViewModel: Profile updated for current user - name: \(newProfile.name), imageURL: \(newProfile.profileImageURL ?? "nil")")
                
                // 프로필 이미지 미리 로딩
                if let profileImageURL = newProfile.profileImageURL {
                    Task {
                        await ImageCache.shared.preloadProfileImage(urlString: profileImageURL)
                    }
                }
            }
        } else if newProfile == nil && userId == appState.currentUserId {
            // 현재 사용자가 로그아웃한 경우
            userProfile = nil
            Logger.info("UserInfoModalViewModel: Profile cleared for logged out user")
        } else {
            // 다른 사용자의 프로필 변경이거나 현재 관찰 중인 사용자가 아닌 경우
            // 직접 프로필을 다시 로드
            await reloadUserProfile()
        }
    }
    
    private func checkForProfileUpdates() async {
        // 현재 프로필과 서버의 최신 프로필을 비교하여 업데이트가 필요한지 체크
        do {
            let latestProfile = try await diContainer.profileUseCase.fetchProfileByUserId(userId: userId)
            
            let hasChanged = userProfile?.name != latestProfile.name || 
                           userProfile?.profileImageURL != latestProfile.profileImageURL ||
                           userProfile?.profileKey != latestProfile.profileKey
            
            if hasChanged {
                userProfile = latestProfile
                Logger.info("UserInfoModalViewModel: Profile auto-updated - name: \(latestProfile.name), imageURL: \(latestProfile.profileImageURL ?? "nil")")
                
                // 프로필 이미지 미리 로딩
                if let profileImageURL = latestProfile.profileImageURL {
                    Task {
                        await ImageCache.shared.preloadProfileImage(urlString: profileImageURL)
                    }
                }
            }
        } catch {
            Logger.error("UserInfoModalViewModel: Failed to check profile updates: \(error.localizedDescription)")
        }
    }
    
    private func reloadUserProfile() async {
        do {
            let freshProfile = try await diContainer.profileUseCase.fetchProfileByUserId(userId: userId)
            
            let hasChanged = userProfile?.name != freshProfile.name || 
                           userProfile?.profileImageURL != freshProfile.profileImageURL ||
                           userProfile?.profileKey != freshProfile.profileKey
            
            if hasChanged {
                userProfile = freshProfile
                Logger.info("UserInfoModalViewModel: Profile reloaded - name: \(freshProfile.name), imageURL: \(freshProfile.profileImageURL ?? "nil")")
                
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
} 
