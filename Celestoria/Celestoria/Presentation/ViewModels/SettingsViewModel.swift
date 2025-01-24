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
    
    init(deleteAccountUseCase: DeleteAccountUseCase) {
        self.deleteAccountUseCase = deleteAccountUseCase
    }
    
    func deleteAccount() async throws {
        try await deleteAccountUseCase.execute()
    }
}
