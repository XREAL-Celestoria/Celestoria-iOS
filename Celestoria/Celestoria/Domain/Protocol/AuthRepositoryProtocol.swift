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
    func updateProfile(name: String?, profileImageURL: String?, spaceThumbnailId: String?, starfield: String?) async throws -> UserProfile
    func fetchProfile() async throws -> UserProfile
    func fetchProfileByUserId(userId: UUID) async throws -> UserProfile
    func fetchAllProfiles(excludingUserId: UUID?) async throws -> [UserProfile]
    func searchProfiles(keyword: String, excludingUserId: UUID?) async throws -> [UserProfile]
    func blockUser(reporterId: UUID, blockedUserId: UUID) async throws
    func fetchBlockedUsers(for userId: UUID) async throws -> [Block]
    func unblockUser(reporterId: UUID, blockedUserId: UUID) async throws
}
