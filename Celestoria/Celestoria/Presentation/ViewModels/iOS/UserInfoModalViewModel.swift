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
        mockMemories = (1...10).map { index in
            MockMemory(
                title: "Memory \(index)",
                views: Int.random(in: 10...100),
                daysAgo: Int.random(in: 1...7)
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
        
        // appState.userProfile이 변경될 때마다 현재 사용자의 프로필 업데이트
        Task {
            for await newProfile in appState.$userProfile.values {
                Logger.info("UserInfoModalViewModel: AppState userProfile changed - newProfile: \(newProfile?.name ?? "nil"), userId: \(newProfile?.userId ?? UUID()), current userId: \(userId)")
                
                // 현재 사용자의 프로필이 변경된 경우에만 업데이트
                if let newProfile = newProfile, newProfile.userId == userId {
                    userProfile = newProfile
                    Logger.info("UserInfoModalViewModel: Profile updated for current user - name: \(newProfile.name), imageURL: \(newProfile.profileImageURL ?? "nil")")
                    // 프로필이 업데이트되면 통계도 다시 로드
                    await loadUserStats()
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
