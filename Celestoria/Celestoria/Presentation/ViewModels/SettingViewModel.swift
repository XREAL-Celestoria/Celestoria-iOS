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
            
            // 최초 선택된 이미지를 기록
            if let urlString = fetchedProfile.profileImageURL,
               let predefined = PredefinedProfileImage.allCases.first(where: { urlString.contains($0.rawValue) }) {
                originalImage = .predefined(predefined)
                selectedImage = .predefined(predefined)
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

        Logger.info("🔁 프로필 업데이트 시작")
        Logger.info("🧾 입력된 이름: \(newName ?? "(nil)")")
        Logger.info("🧾 선택된 이미지 타입: \(String(describing: selectedImage))")

        isLoading = true
        defer { isLoading = false }

        // 선택된 이미지 → UIImage 변환
        let imageToUpload: UIImage? = {
            guard let selected = selectedImage else {
                Logger.info("📷 선택된 이미지 없음")
                return nil
            }

            switch selected {
            case .custom(let image):
                Logger.info("📷 사용자 커스텀 이미지 선택됨")
                return image

            case .predefined(let predefined):
                let image = UIImage(named: predefined.rawValue)
                if image == nil {
                    Logger.error("❌ UIImage(named: \(predefined.rawValue)) 로드 실패")
                } else {
                    Logger.info("✅ UIImage(named: \(predefined.rawValue)) 로드 성공")
                }
                return image
            }
        }()

        do {
            Logger.info("🚀 updateProfile 호출 중...")
            profile = try await profileUseCase.updateProfile(
                name: newName,
                image: imageToUpload,
                userId: userId
            )
            Logger.info("✅ 서버 업데이트 완료")

            self.selectedImage = selectedImage // 현재 상태 업데이트
            Logger.info("🔄 ViewModel 상태 갱신 완료")
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
        do {
            guard let userId = appModel.userId else {
                Logger.error("User ID not found")
                return
            }
            
            Logger.info("Updating thumbnail ID: \(thumbnailId)")
            profile = try await profileUseCase.updateProfile(
                name: profile?.name,
                image: nil,
                spaceThumbnailId: thumbnailId,
                userId: userId
            )
            Logger.info("Thumbnail updated successfully")
        } catch {
            self.error = error
            Logger.error("Error updating thumbnail: \(error.localizedDescription)")
        }
        isLoading = false
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
