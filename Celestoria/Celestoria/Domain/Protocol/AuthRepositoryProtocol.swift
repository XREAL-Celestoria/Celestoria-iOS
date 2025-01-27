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
    func updateProfile(name: String?, profileImageURL: String?) async throws -> UserProfile
    func fetchProfile() async throws -> UserProfile
}
