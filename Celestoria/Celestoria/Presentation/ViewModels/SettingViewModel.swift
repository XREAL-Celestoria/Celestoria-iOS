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
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    
    private let deleteAccountUseCase: DeleteAccountUseCase
    private let signOutUseCase: SignOutUseCase
    private let profileUseCase: ProfileUseCase
    private let blockedUsersUseCase: BlockedUsersUseCase
    private let appModel: AppModel
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
    
    init(deleteAccountUseCase: DeleteAccountUseCase,
         signOutUseCase: SignOutUseCase,
         profileUseCase: ProfileUseCase,
         blockedUsersUseCase: BlockedUsersUseCase,
         appModel: AppModel) {
        self.deleteAccountUseCase = deleteAccountUseCase
        self.signOutUseCase = signOutUseCase
        self.profileUseCase = profileUseCase
        self.blockedUsersUseCase = blockedUsersUseCase
        self.appModel = appModel
        
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
            } else if let urlString = fetchedProfile.profileImageURL,
                      let url = URL(string: urlString),
                      let data = try? Data(contentsOf: url),
                      let image = UIImage(data: data) {
                originalImage = .custom(image)
                selectedImage = .custom(image)
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
        guard let userId = appModel.userId else {
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
            updateUploadEnabled()

            Logger.info("✅ 프로필 업데이트 완료")
        } catch {
            self.error = error
            Logger.error("❌ 프로필 업데이트 실패: \(error.localizedDescription)")
        }
    }
    
    func signOut() async throws {
        try await signOutUseCase.execute()
        appModel.userId = nil
        await dismissImmersiveSpace()
        appModel.isImmersiveViewActive = false
        appModel.hasAcceptedTerms = false
        appModel.activeScreen = .login
    }
    
    func deleteAccount() async throws {
        try await deleteAccountUseCase.execute()
        appModel.userId = nil
        await dismissImmersiveSpace()
        appModel.isImmersiveViewActive = false
        appModel.hasAcceptedTerms = false
        appModel.activeScreen = .login
    }
    
    func updateThumbnail(thumbnailId: String) async {
        isLoading = true
        defer { isLoading = false }

        do {
            guard let userId = appModel.userId else {
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
        guard let userId = appModel.userId else { return }
        
        isLoadingBlockedUsers = true
        defer { isLoadingBlockedUsers = false }
        
        do {
            blockedUsers = try await blockedUsersUseCase.fetchBlockedUsers(for: userId)
        } catch {
            Logger.error("Failed to fetch blocked users: \(error.localizedDescription)")
        }
    }
    
    func unblockUser(_ blockedUserId: UUID) async {
        guard let currentUserId = appModel.userId else { return }
        
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
}
