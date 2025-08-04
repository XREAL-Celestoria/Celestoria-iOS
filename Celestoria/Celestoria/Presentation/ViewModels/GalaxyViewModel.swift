//
//  GalaxyViewModel.swift
//  Celestoria
//
//  Created by Park Seyoung on 1/26/25.
//

import Foundation
import os

@MainActor
class GalaxyViewModel: ObservableObject {
    @Published var selectedImage: String? // 현재 선택된 starfield(이미지) 이름
    #if os(visionOS)
    private let spaceCoordinator: SpaceCoordinator
    #endif
    private let profileUseCase: ProfileUseCase
    let appState: AppState
    
    // Memory 관련 속성 추가 (iOS용)
    @Published var memories: [Memory] = []
    @Published var isLoading = false
    @Published var spaceThumbnail: String?
    private let memoryUseCase: FetchMemoriesUseCase

    #if os(visionOS)
    init(appState: AppState, spaceCoordinator: SpaceCoordinator, profileUseCase: ProfileUseCase, memoryUseCase: FetchMemoriesUseCase) {
        self.appState = appState
        self.spaceCoordinator = spaceCoordinator
        self.profileUseCase = profileUseCase
        self.memoryUseCase = memoryUseCase
        
        // 초기 상태 설정
        self.selectedImage = StarField.FIELD_1.imageName
        
        // userProfile 변경 관찰
        Task {
            // 먼저 현재 프로필 가져오기 시도
            if appState.userId != nil {
                do {
                    let currentProfile = try await profileUseCase.fetchProfile()
                    if let starfieldName = currentProfile.starfield {
                        self.selectedImage = starfieldName
                        #if os(visionOS)
                        self.spaceCoordinator.updateBackground(with: starfieldName)
                        #endif
                    }
                } catch {
                    Logger.error("Failed to fetch initial profile: \(error.localizedDescription)")
                }
            }
            
            // 이후 변경사항 관찰
            for await newProfile in appState.$userProfile.values {
                if let starfieldName = newProfile?.starfield {
                    self.selectedImage = starfieldName
                    #if os(visionOS)
                    self.spaceCoordinator.updateBackground(with: starfieldName)
                    #endif
                } else {
                    self.selectedImage = StarField.FIELD_1.imageName
                }
                Logger.info("GalaxyViewModel observer: userProfile changed to \(String(describing: newProfile?.starfield)) => selectedImage = \(String(describing: self.selectedImage))")
            }
        }
    }
    #else
    init(appState: AppState, profileUseCase: ProfileUseCase, memoryUseCase: FetchMemoriesUseCase) {
        self.appState = appState
        self.profileUseCase = profileUseCase
        self.memoryUseCase = memoryUseCase
        
        // 초기 상태 설정
        self.selectedImage = StarField.FIELD_1.imageName
        
        // userProfile 변경 관찰
        Task {
            // 먼저 현재 프로필 가져오기 시도
            if appState.userId != nil {
                do {
                    let currentProfile = try await profileUseCase.fetchProfile()
                    if let starfieldName = currentProfile.starfield {
                        self.selectedImage = starfieldName
                    }
                } catch {
                    Logger.error("Failed to fetch initial profile: \(error.localizedDescription)")
                }
            }
            
            // 이후 변경사항 관찰
            for await newProfile in appState.$userProfile.values {
                if let starfieldName = newProfile?.starfield {
                    self.selectedImage = starfieldName
                } else {
                    self.selectedImage = StarField.FIELD_1.imageName
                }
                Logger.info("GalaxyViewModel observer: userProfile changed to \(String(describing: newProfile?.starfield)) => selectedImage = \(String(describing: self.selectedImage))")
            }
        }
    }
    #endif

    // GalaxyView에서 이미지 클릭 시 호출
    func selectImage(with imageName: String) {
        // 이미 선택된 이미지이면 무시
        guard selectedImage != imageName else { return }
        selectedImage = imageName
        Logger.info("GalaxyViewModel selectImage: \(imageName)")
    }

    // Save 버튼 클릭 시
    func saveSelectedImage() {
        guard let imageName = selectedImage else { return }
        Logger.info("GalaxyViewModel saveSelectedImage: \(imageName)")
        
        // 비로그인 상태면 갱신 불가 -> 그냥 리턴(원하면 Alert 처리 등)
        guard let userId = appState.userId else {
            Logger.info("GalaxyViewModel: no user -> cannot update DB.")
            return
        }

        Task {
            do {
                // DB의 starfield 업데이트
                let updatedProfile = try await profileUseCase.updateProfile(
                    starfield: imageName,
                    userId: userId
                )
                
                // AppState에 반영 -> didSet에서 selectedStarfield 업데이트
                appState.userProfile = updatedProfile
                
                // Immersive 공간 업데이트
                #if os(visionOS)
                spaceCoordinator.updateBackground(with: imageName)
                #endif
                
            } catch {
                Logger.error("Failed to update starfield: \(error.localizedDescription)")
            }
        }
    }

    // Save 버튼 활성화 여부
    var isUploadEnabled: Bool {
        // 비로그인 상태는 저장 불가
        guard appState.userId != nil else { return false }
        // 현재 DB 값과 다를 때만 true
        guard let imageName = selectedImage else { return false }
        if let dbValue = appState.userProfile?.starfield {
            return imageName != dbValue
        }
        // userProfile.starfield가 없다면(true) → 보통 없을 일은 없지만...
        return true
    }

    // 그리드에서 체크 표시를 위해
    func isSelected(image: String) -> Bool {
        return selectedImage == image
    }
    
    // 갤럭시 새로고침 메서드
    func refreshGalaxy() {
        Logger.info("GalaxyViewModel: Refreshing galaxy")
        Task {
            if let userId = appState.galaxyTargetUserId {
                do {
                    if userId == appState.currentUserId {
                        try await fetchCurrentUserMemories()
                    } else {
                        try await fetchMemoriesFromOtherUser(userId: userId)
                    }
                } catch {
                    Logger.error("Failed to refresh galaxy: \(error)")
                }
            }
        }
    }
    
    // 메모리 관련 메서드들 (iOS와 visionOS 공통)
    func fetchCurrentUserMemories() async throws {
        guard let userId = appState.userId else { return }
        isLoading = true
        defer { isLoading = false }
        
        do {
            memories = try await memoryUseCase.execute(for: userId)
            // 프로필에서 썸네일 가져오기
            if let profile = appState.userProfile,
               let thumbnailId = profile.spaceThumbnailId,
               let thumbnailIdInt = Int(thumbnailId) {
                spaceThumbnail = "spaceThumbnail\(String(format: "%02d", thumbnailIdInt))"
            }
        } catch {
            Logger.error("Failed to fetch memories: \(error)")
            throw error
        }
    }
    
    func fetchMemoriesFromOtherUser(userId: UUID) async throws {
        isLoading = true
        defer { isLoading = false }
        
        do {
            memories = try await memoryUseCase.execute(for: userId)
            // 다른 사용자의 프로필에서 썸네일 가져오기
            let profile = try await profileUseCase.fetchProfileByUserId(userId: userId)
            if let thumbnailId = profile.spaceThumbnailId,
               let thumbnailIdInt = Int(thumbnailId) {
                spaceThumbnail = "spaceThumbnail\(String(format: "%02d", thumbnailIdInt))"
            }
            // 다른 사용자의 starfield 설정도 반영
            if let starfieldName = profile.starfield {
                selectedImage = starfieldName
            }
        } catch {
            Logger.error("Failed to fetch other user memories: \(error)")
            
            // Profile not found 에러인 경우 현재 사용자로 fallback
            if error.localizedDescription.contains("Profile not found") {
                Logger.info("Profile not found for user \(userId), falling back to current user")
                if let currentUserId = appState.currentUserId {
                    appState.galaxyTargetUserId = currentUserId
                    try await fetchCurrentUserMemories()
                    return
                }
            }
            
            throw error
        }
    }
}
