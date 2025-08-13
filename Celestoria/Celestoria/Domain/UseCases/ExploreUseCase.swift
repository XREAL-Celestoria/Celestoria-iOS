//
//  ExploreUseCase.swift
//  Celestoria
//
//  Created by Minjun Kim on 1/28/25.
//

import Foundation
import Supabase
import os

/// 유저 정보 + 메모리 개수 + 좋아요 개수를 담는 DTO
struct ExploreUser {
    let profile: UserProfile
    let memoryCount: Int
    let likeCount: Int
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
    /// 그리고 `excludeUserId`를 기준으로 "본인 제외" (하지만 iOS에서는 포함).
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
            // iOS에서는 현재 유저도 포함하도록 수정
            userProfiles = try await authRepository.fetchAllProfiles(
                excludingUserId: nil
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
                memoryCount: memoryCountMap[profile.userId] ?? 0,
                likeCount: 0 // 기존 호환성을 위해 0으로 설정
            )
        }
        .sorted(by: { $0.memoryCount > $1.memoryCount })

        return result
    }
    
    /// 좋아요 순서로 정렬된 유저 목록 가져오기
    func fetchPopularUsers(
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
                excludingUserId: nil
            )
        }
        
        // 모든 메모리 가져오기
        let allMemories = try await memoryRepository.fetchAllMemories()
        
        // 효율적으로 유저별 총 좋아요 수 가져오기 (RPC 함수가 없으면 fallback 사용)
        let userLikeCounts: [UUID: Int]
        do {
            userLikeCounts = try await memoryRepository.getAllUsersLikeCounts()
        } catch {
            // RPC 함수가 없으면 fallback 메서드 사용
            userLikeCounts = try await memoryRepository.getAllUsersLikeCountsFallback()
        }
        
        // 메모리 개수 계산
        var memoryCountMap: [UUID: Int] = [:]
        for memory in allMemories {
            memoryCountMap[memory.userId, default: 0] += 1
        }
        
        // ExploreUser로 만들고 좋아요 순서로 정렬
        let result: [ExploreUser] = userProfiles.map { profile in
            ExploreUser(
                profile: profile,
                memoryCount: memoryCountMap[profile.userId] ?? 0,
                likeCount: userLikeCounts[profile.userId] ?? 0
            )
        }
        .filter { $0.likeCount > 0 } // 좋아요가 0개인 유저 제외
        .sorted(by: { $0.likeCount > $1.likeCount })
        .prefix(5) // 최대 5개까지만
        .map { $0 } // ArraySlice를 Array로 변환
        
        return result
    }
    
    /// 최신 가입 순서로 정렬된 유저 목록 가져오기 (페이지네이션 지원)
    func fetchLatestUsers(
        searchText: String?,
        excludeUserId: UUID?,
        page: Int,
        limit: Int
    ) async throws -> [ExploreUser] {
        
        let userProfiles: [UserProfile]
        if let text = searchText, !text.isEmpty {
            userProfiles = try await authRepository.searchProfiles(
                keyword: text,
                excludingUserId: excludeUserId
            )
        } else {
            userProfiles = try await authRepository.fetchAllProfiles(
                excludingUserId: nil
            )
        }
        
        // 모든 메모리 가져오기
        let allMemories = try await memoryRepository.fetchAllMemories()
        
        // 메모리 개수 계산
        var memoryCountMap: [UUID: Int] = [:]
        for memory in allMemories {
            memoryCountMap[memory.userId, default: 0] += 1
        }
        
        // ExploreUser로 만들고 가입 순서로 정렬 (최신 가입이 먼저)
        let sortedUsers: [ExploreUser] = userProfiles.map { profile in
            ExploreUser(
                profile: profile,
                memoryCount: memoryCountMap[profile.userId] ?? 0,
                likeCount: 0
            )
        }
        .sorted(by: { $0.profile.createdAt > $1.profile.createdAt }) // 최신 가입 순서
        
        // 페이지네이션 적용
        let startIndex = (page - 1) * limit
        let endIndex = min(startIndex + limit, sortedUsers.count)
        
        guard startIndex < sortedUsers.count else {
            return []
        }
        
        return Array(sortedUsers[startIndex..<endIndex])
    }
}
