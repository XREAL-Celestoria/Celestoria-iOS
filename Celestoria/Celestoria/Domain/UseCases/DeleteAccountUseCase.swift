//
//  DeleteAccountUseCase.swift
//  Celestoria
//
//  Created by Park Seyoung on 1/20/25.
//

import Foundation

@MainActor
final class DeleteAccountUseCase: ObservableObject {
    private let repository: AuthRepositoryProtocol

    init(repository: AuthRepositoryProtocol) {
        self.repository = repository
    }

    func execute() async throws {
        try await repository.deleteAccount()
    }
}
