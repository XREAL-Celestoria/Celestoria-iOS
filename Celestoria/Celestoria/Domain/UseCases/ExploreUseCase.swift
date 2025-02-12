//
//  ExploreUseCase.swift
//  Celestoria
//
//  Created by Minjun Kim on 1/28/25.
//

import Foundation
import Supabase
import os

/// 유저 정보 + 메모리 개수를 담는 DTO
struct ExploreUser {
    let profile: UserProfile
    let memoryCount: Int
}

final class ExploreUseCase {
    private let authRepository: AuthRepositoryProtocol
    private let memoryRepository: MemoryRepository

    init(
        authRepository: AuthRepositoryProtocol,
        memoryRepository: MemoryRepository
    ) {
        self.authRepository = authRepository
        self.memoryRepository = memoryRepository
    }

    /// searchText가 nil/빈값이면 -> 모든 유저,
    /// 그렇지 않으면 -> LIKE 검색,
    /// 그리고 `excludeUserId`를 기준으로 "본인 제외".
    func fetchExploreUsers(
        searchText: String?,
        excludeUserId: UUID?
    ) async throws -> [ExploreUser] {

        let userProfiles: [UserProfile]
        if let text = searchText, !text.isEmpty {
            userProfiles = try await authRepository.searchProfiles(
                keyword: text,
                excludingUserId: excludeUserId
            )
        } else {
            userProfiles = try await authRepository.fetchAllProfiles(
                excludingUserId: excludeUserId
            )
        }

        // 2) 모든 메모리 한 번에 가져온다
        let allMemories = try await memoryRepository.fetchAllMemories()

        // 3) userId 기준으로 groupBy 해서 개수 세기
        var memoryCountMap: [UUID: Int] = [:]
        for mem in allMemories {
            memoryCountMap[mem.userId, default: 0] += 1
        }

        // 4) [ExploreUser] 로 만들고, memoryCount DESC 정렬
        let result: [ExploreUser] = userProfiles.map { profile in
            ExploreUser(
                profile: profile,
                memoryCount: memoryCountMap[profile.userId] ?? 0
            )
        }
        .sorted(by: { $0.memoryCount > $1.memoryCount })

        return result
    }
}
