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
    private let deleteAccountUseCase: DeleteAccountUseCase
    private let signOutUseCase: SignOutUseCase
    private let profileUseCase: ProfileUseCase
    private let appModel: AppModel
    
    @Published var profile: UserProfile?
    @Published var isLoading = false
    @Published var error: Error?
    
    init(deleteAccountUseCase: DeleteAccountUseCase,
         signOutUseCase: SignOutUseCase,
         profileUseCase: ProfileUseCase,
         appModel: AppModel) {
        self.deleteAccountUseCase = deleteAccountUseCase
        self.signOutUseCase = signOutUseCase
        self.profileUseCase = profileUseCase
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
            Logger.info("Updating profile - Name: \(String(describing: name)), Has Image: \(image != nil)")
            profile = try await profileUseCase.updateProfile(name: name, image: image)
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
        appModel.activeScreen = .login
    }
    
    func deleteAccount() async throws {
        try await deleteAccountUseCase.execute()
        appModel.userId = nil
        appModel.activeScreen = .login
    }
}
