//
//  SettingsViewModel.swift
//  Celestoria
//
//  Created by Minjun Kim on 1/24/25.
//

import Foundation
import SwiftUI
import os

@MainActor
class SettingViewModel: ObservableObject {
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    
    private let deleteAccountUseCase: DeleteAccountUseCase
    private let signOutUseCase: SignOutUseCase
    private let profileUseCase: ProfileUseCase
    private let blockedUsersUseCase: BlockedUsersUseCase
    private let appModel: AppModel
    
    @Published var profile: UserProfile?
    @Published var isLoading = false
    @Published var error: Error?
    @Published var blockedUsers: [BlockedUserInfo] = []
    @Published var isLoadingBlockedUsers = false
    
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
        do {
            profile = try await profileUseCase.fetchProfile()
            Logger.info("Fetched profile: \(String(describing: profile))")
        } catch {
            self.error = error
            Logger.error("Error fetching profile: \(error.localizedDescription)")
        }
        isLoading = false
    }
    
    func updateProfile(name: String?, image: UIImage?) async {
        isLoading = true
        do {
            guard let userId = appModel.userId else {
                Logger.error("User ID not found")
                return
            }
            
            Logger.info("Updating profile - Name: \(String(describing: name)), Has Image: \(image != nil)")
            profile = try await profileUseCase.updateProfile(
                name: name,
                image: image,
                userId: userId
            )
            Logger.info("Profile updated successfully: \(String(describing: profile))")
        } catch {
            self.error = error
            Logger.error("Error updating profile: \(error.localizedDescription)")
        }
        isLoading = false
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
