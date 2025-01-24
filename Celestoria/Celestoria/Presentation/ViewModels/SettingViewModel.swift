//
//  SettingsViewModel.swift
//  Celestoria
//
//  Created by Minjun Kim on 1/24/25.
//

import Foundation

@MainActor
final class SettingViewModel: ObservableObject {
    private let deleteAccountUseCase: DeleteAccountUseCase
    private let signOutUseCase: SignOutUseCase
    private let appModel: AppModel
    
    init(deleteAccountUseCase: DeleteAccountUseCase, signOutUseCase: SignOutUseCase, appModel: AppModel) {
        self.deleteAccountUseCase = deleteAccountUseCase
        self.signOutUseCase = signOutUseCase
        self.appModel = appModel
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
