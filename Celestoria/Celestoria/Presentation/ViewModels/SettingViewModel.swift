//
//  SettingsViewModel.swift
//  Celestoria
//
//  Created by Minjun Kim on 1/24/25.
//

import Foundation
import SwiftUI
import os
import _PhotosUI_SwiftUI

@MainActor
class SettingViewModel: ObservableObject {
    #if os(visionOS)
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    #endif
    
    private let deleteAccountUseCase: DeleteAccountUseCase
    private let signOutUseCase: SignOutUseCase
    private let profileUseCase: ProfileUseCase
    private let blockedUsersUseCase: BlockedUsersUseCase
    public let appState: AppState
    public var originalImage: ProfileImageSelection?
    
    //안에 닉네임
    @Published var profile: UserProfile?
    @Published var isLoading = false
    @Published var error: Error?
    @Published var blockedUsers: [BlockedUserInfo] = []
    @Published var isLoadingBlockedUsers = false
    @Published var selectedImage: ProfileImageSelection?
    @Published var customPhotoselectedItem: PhotosPickerItem? = nil
    @Published var isUploadEnabled: Bool = false
    
    // 이미지 캐싱을 위한 프로퍼티
    private var cachedCustomImage: UIImage?
    private var cachedImageURL: String?
    
    init(deleteAccountUseCase: DeleteAccountUseCase,
         signOutUseCase: SignOutUseCase,
         profileUseCase: ProfileUseCase,
         blockedUsersUseCase: BlockedUsersUseCase,
         appState: AppState) {
        self.deleteAccountUseCase = deleteAccountUseCase
        self.signOutUseCase = signOutUseCase
        self.profileUseCase = profileUseCase
        self.blockedUsersUseCase = blockedUsersUseCase
        self.appState = appState
        
        Task {
            await fetchProfile()
        }
    }
    
    func fetchProfile() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let fetchedProfile = try await profileUseCase.fetchProfile()
            profile = fetchedProfile

            if let key = fetchedProfile.profileKey,
               let predefined = PredefinedProfileImage.fromKey(key) {
                originalImage = .predefined(predefined)
                selectedImage = .predefined(predefined)
            } else if let urlString = fetchedProfile.profileImageURL {
                // 캐시된 이미지가 있고 URL이 같으면 캐시 사용
                if let cachedImage = cachedCustomImage, cachedImageURL == urlString {
                    originalImage = .custom(cachedImage)
                    selectedImage = .custom(cachedImage)
                } else {
                    // 새로운 이미지 로드 (비동기 방식)
                    if let url = URL(string: urlString) {
                        do {
                            let (data, _) = try await URLSession.shared.data(from: url)
                            if let image = UIImage(data: data) {
                                // 캐시에 저장
                                cachedCustomImage = image
                                cachedImageURL = urlString
                                originalImage = .custom(image)
                                selectedImage = .custom(image)
                            } else {
                                originalImage = nil
                                selectedImage = nil
                            }
                        } catch {
                            Logger.error("Error loading profile image: \(error.localizedDescription)")
                            originalImage = nil
                            selectedImage = nil
                        }
                    } else {
                        originalImage = nil
                        selectedImage = nil
                    }
                }
            } else {
                originalImage = nil
                selectedImage = nil
            }

            updateUploadEnabled()
        } catch {
            self.error = error
            Logger.error("Error fetching profile: \(error.localizedDescription)")
        }
    }
    
    func updateUploadEnabled() {
        isUploadEnabled = selectedImage != originalImage
    }
    
    func updateProfileIfNeeded(newName: String?, selectedImage: ProfileImageSelection?) async {
        guard let userId = appState.userId else {
            Logger.error("🛑 User ID not found")
            return
        }

        let originalName = profile?.name ?? ""
        let nameChanged = (newName ?? "") != originalName
        let imageChanged = selectedImage != originalImage

        if !nameChanged && !imageChanged {
            Logger.info("📭 이름과 이미지 모두 변경 없음 - 업데이트 생략")
            return
        }

        Logger.info("🔁 프로필 업데이트 시작")

        let imageDataToUpload: Data?
        let profileKeyToUpload: Int?

        switch selectedImage {
        case .custom(let image):
            imageDataToUpload = image.jpegData(compressionQuality: 0.8)
            profileKeyToUpload = nil 
        case .predefined(let predefined):
            imageDataToUpload = nil
            profileKeyToUpload = predefined.key
        case .none:
            imageDataToUpload = nil
            profileKeyToUpload = nil
        }

        isLoading = true
        defer { isLoading = false }

        do {
            Logger.info("🚀 updateProfile 호출 중...")

            profile = try await profileUseCase.updateProfile(
                name: newName,
                profileKey: profileKeyToUpload,
                imageData: imageDataToUpload,
                userId: userId
            )

            self.selectedImage = selectedImage
            self.originalImage = selectedImage  // 원본 이미지도 업데이트하여 다음 편집 시 올바른 상태 유지
            updateUploadEnabled()
            
            // AppState 업데이트하여 다른 뷰들에 반영
            appState.userProfile = profile
            
            // userProfile 업데이트가 완전히 처리될 시간을 주기 위해 약간의 지연 추가
            try? await Task.sleep(nanoseconds: 50_000_000) // 0.05초 지연
            appState.refreshMainView = true

            Logger.info("✅ 프로필 업데이트 완료 - name: \(profile?.name ?? "nil"), imageURL: \(profile?.profileImageURL ?? "nil")")
            Logger.info("✅ AppState 업데이트 완료 - userProfile: \(appState.userProfile?.name ?? "nil"), refreshMainView: \(appState.refreshMainView)")
        } catch {
            self.error = error
            Logger.error("❌ 프로필 업데이트 실패: \(error.localizedDescription)")
        }
    }
    
    func signOut() async throws {
        try await signOutUseCase.execute()
        appState.userId = nil
        appState.userProfile = nil
        
        #if os(visionOS)
        await dismissImmersiveSpace()
        appState.isImmersiveViewActive = false
        appState.hasAcceptedTerms = false
        appState.activeScreen = .login
        #else
        // iOS에서는 navigationState 사용
        appState.navigationState = .login
        // UserDefaults에서 약관 동의 상태 제거
        UserDefaults.standard.removeObject(forKey: "hasAcceptedTerms")
        #endif
    }
    
    func deleteAccount() async throws {
        try await deleteAccountUseCase.execute()
        appState.userId = nil
        appState.userProfile = nil
        
        #if os(visionOS)
        await dismissImmersiveSpace()
        appState.isImmersiveViewActive = false
        appState.hasAcceptedTerms = false
        appState.activeScreen = .login
        #else
        // iOS에서는 navigationState 사용
        appState.navigationState = .login
        // UserDefaults에서 약관 동의 상태 제거
        UserDefaults.standard.removeObject(forKey: "hasAcceptedTerms")
        #endif
    }
    
    func updateThumbnail(thumbnailId: String) async {
        isLoading = true
        defer { isLoading = false }

        do {
            guard let userId = appState.userId else {
                Logger.error("🛑 User ID not found")
                return
            }

            Logger.info("📤 Updating thumbnail ID: \(thumbnailId)")
            profile = try await profileUseCase.updateProfile(
                spaceThumbnailId: thumbnailId,
                userId: userId
            )
            Logger.info("✅ Thumbnail updated successfully")
        } catch {
            self.error = error
            Logger.error("❌ Error updating thumbnail: \(error.localizedDescription)")
        }
    }
    
    // Helper function to convert between thumbnail formats
    func getThumbnailImageName(from id: String?) -> String {
        return "Thumbnail\(id ?? "1")"
    }
    
    func getThumbnailId(from imageName: String) -> String {
        return imageName.replacingOccurrences(of: "Thumbnail", with: "")
    }
    
    func fetchBlockedUsers() async {
        guard let userId = appState.userId else { return }
        
        isLoadingBlockedUsers = true
        defer { isLoadingBlockedUsers = false }
        
        do {
            blockedUsers = try await blockedUsersUseCase.fetchBlockedUsers(for: userId)
        } catch {
            Logger.error("Failed to fetch blocked users: \(error.localizedDescription)")
        }
    }
    
    func unblockUser(_ blockedUserId: UUID) async {
        guard let currentUserId = appState.userId else { return }
        
        do {
            try await blockedUsersUseCase.unblockUser(
                reporterId: currentUserId,
                blockedUserId: blockedUserId
            )
            await fetchBlockedUsers()
        } catch {
            Logger.error("Failed to unblock user: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Login Reset Methods
    
    /// 로그인 상태를 완전히 초기화하고 로그인 화면으로 이동합니다.
    func resetToLogin() {
        // AppState 초기화
        appState.userId = nil
        appState.userProfile = nil
        
        // UserDefaults에서 관련 데이터 제거
        UserDefaults.standard.removeObject(forKey: "userId")
        UserDefaults.standard.removeObject(forKey: "hasAcceptedTerms")
        
        // iOS에서는 navigationState 사용
        #if os(iOS)
        appState.navigationState = .login
        #else
        appState.activeScreen = .login
        #endif
        
        Logger.info("Login state reset - User logged out and redirected to login")
    }
}
