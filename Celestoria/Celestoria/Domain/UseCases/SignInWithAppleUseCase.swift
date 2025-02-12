//
//  SignInWithAppleUseCase.swift
//  Celestoria
//
//  Created by Park Seyoung on 1/20/25.
//

import Foundation

struct SignInWithAppleUseCase {
    private let repository: AuthRepositoryProtocol

    init(repository: AuthRepositoryProtocol) {
        self.repository = repository
    }

    func execute(idToken: String) async throws -> UUID {
        let userId = try await repository.signInWithApple(idToken: idToken)

        return userId
    }
}
