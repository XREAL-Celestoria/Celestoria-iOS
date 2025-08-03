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
    
    // MARK: - Dependencies
    private let diContainer: DIContainer
    private let userId: UUID
    private let appState: AppState
    
    // MARK: - Initialization
    init(diContainer: DIContainer, userId: UUID) {
        self.diContainer = diContainer
        self.userId = userId
        self.appState = diContainer.appState
        
        Logger.info("UserInfoModalViewModel: Initialized for userId: \(userId)")
        
        loadUserData()
        setupRefreshObserver()
    }
    
    // MARK: - Public Methods
    func loadUserData() {
        Task {
            await loadUserProfile()
            await loadUserStats()
        }
    }
    
    // MARK: - Private Methods
    private func loadUserProfile() async {
        do {
            userProfile = try await diContainer.profileUseCase.fetchProfileByUserId(userId: userId)
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
} 
