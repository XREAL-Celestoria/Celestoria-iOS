//
//  BlockedUsersUseCase.swift
//  Celestoria
//
//  Created by Minjun Kim on 2/6/25.
//

import Foundation
import os

struct BlockedUsersUseCase {
    private let authRepository: AuthRepositoryProtocol
    
    init(authRepository: AuthRepositoryProtocol) {
        self.authRepository = authRepository
    }
    
    func fetchBlockedUsers(for userId: UUID) async throws -> [BlockedUserInfo] {
        let blockedUsers = try await authRepository.fetchBlockedUsers(for: userId)
        
        var blockedUserInfos: [BlockedUserInfo] = []
        for block in blockedUsers {
            do {
                let userProfile = try await authRepository.fetchProfileByUserId(userId: block.blockedUserId)
                blockedUserInfos.append(BlockedUserInfo(block: block, profile: userProfile))
            } catch {
                Logger.error("Failed to fetch profile for blocked user: \(error.localizedDescription)")
                continue
            }
        }
        
        return blockedUserInfos
    }
    
    func unblockUser(reporterId: UUID, blockedUserId: UUID) async throws {
        try await authRepository.unblockUser(reporterId: reporterId, blockedUserId: blockedUserId)
    }
}

struct BlockedUserInfo: Identifiable {
    let block: Block
    let profile: UserProfile
    
    var id: UUID { block.id }
}