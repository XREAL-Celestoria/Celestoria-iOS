//
//  AuthRepository.swift
//  Celestoria
//
//  Created by Park Seyoung on 1/20/25.
//

import Foundation

protocol AuthRepositoryProtocol {
    func signInWithApple(idToken: String) async throws -> UUID
    func signOut() async throws
    func deleteAccount() async throws
}
