//
//  AuthRepository.swift
//  Celestoria
//
//  Created by Park Seyoung on 1/20/25.
//

import Foundation
import Supabase
import os

class AuthRepository: AuthRepositoryProtocol {
    private let supabase: SupabaseClient

    init(supabase: SupabaseClient) {
        self.supabase = supabase
    }

    // supabase의 trigger 끄고, 여기서 직접 넣어줌
    func signInWithApple(idToken: String) async throws -> UUID {
        try await supabase.auth.signInWithIdToken(
            credentials: .init(provider: .apple, idToken: idToken)
        )
        
        guard let userId = supabase.auth.currentUser?.id else {
            throw NSError(domain: "AuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not found after sign-in."])
        }
        
        let existingProfile: [UserProfile] = try await supabase
            .from("user_profiles")
            .select("*")
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value
        
        if existingProfile.isEmpty {
            let randomSuffix = String(format: "%04d", Int.random(in: 1000...9999))
            let username = "User_\(randomSuffix)"
            let randomStarfield = StarField.random().imageName

            let profile = UserProfile(
                id: UUID(),
                userId: userId,
                name: username,
                profileImageURL: nil,
                spaceThumbnailId: "1",
                createdAt: Date(),
                starfield: randomStarfield
            )
            
            try await supabase
                .from("user_profiles")
                .upsert(profile)
                .execute()
        }

        return userId
    }

    func signOut() async throws {
        try await supabase.auth.signOut()
    }

    func deleteAccount() async throws {
        try await supabase.rpc("delete_current_user").execute()
        try await supabase.auth.signOut()
    }

    func updateProfile(name: String? = nil, profileImageURL: String? = nil, spaceThumbnailId: String? = nil, starfield: String? = nil) async throws -> UserProfile {
        guard let userId = supabase.auth.currentUser?.id else {
            Logger.error("User not found when updating profile")
            throw NSError(domain: "AuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not found."])
        }
        
        Logger.info("Updating profile for user \(userId) - Name: \(String(describing: name)), ImageURL: \(String(describing: profileImageURL)), starfield: \(String(describing: starfield))")
        
        struct ProfileUpdate: Encodable {
            var name: String?
            var profile_image_url: String?
            var space_thumbnail_id: String?
            var starfield: String?
        }
        
        let updates = ProfileUpdate(
            name: name,
            profile_image_url: profileImageURL,
            space_thumbnail_id: spaceThumbnailId,
            starfield: starfield
        )
        
        do {
            let updatedProfiles: [UserProfile] = try await supabase
                .from("user_profiles")
                .update(updates)
                .eq("user_id", value: userId.uuidString)
                .select()
                .execute()
                .value
            
            guard let profile = updatedProfiles.first else {
                Logger.error("No profile returned after update")
                throw NSError(domain: "AuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to update profile."])
            }
            
            Logger.info("Profile updated successfully: \(profile)")
            return profile
        } catch {
            Logger.error("Error updating profile in Supabase: \(error.localizedDescription)")
            throw error
        }
    }

    func fetchProfile() async throws -> UserProfile {
        guard let userId = supabase.auth.currentUser?.id else {
            throw NSError(domain: "AuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not found."])
        }
        
        let profiles: [UserProfile] = try await supabase
            .from("user_profiles")
            .select()
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value
        
        guard let profile = profiles.first else {
            throw NSError(domain: "AuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Profile not found."])
        }
        
        return profile
    }

    func fetchProfileByUserId(userId: UUID) async throws -> UserProfile {
        let profiles: [UserProfile] = try await supabase
            .from("user_profiles")
            .select()
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value

        guard let profile = profiles.first else {
            throw NSError(domain: "AuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Profile not found."])
        }
        
        return profile
    }

    func fetchAllProfiles(excludingUserId: UUID?) async throws -> [UserProfile] {
    if let userId = excludingUserId {
        // 1. 먼저 차단한 사용자 ID 목록을 가져옴
        let blockedUsers: [Block] = try await supabase
            .from("blocks")
            .select()
            .eq("reporter_id", value: userId.uuidString)
            .execute()
            .value
        
        let blockedUserIds = blockedUsers.map { $0.blockedUserId.uuidString }
        
        // 2. 차단된 사용자를 제외한 프로필 조회
        let query = supabase
            .from("user_profiles")
            .select()
            .neq("user_id", value: userId.uuidString)  // 자신 제외
        
        if !blockedUserIds.isEmpty {
            // 수정된 부분: 각 차단된 ID에 대해 개별적으로 neq 필터 적용
            var filteredQuery = query
            for blockedId in blockedUserIds {
                filteredQuery = filteredQuery.neq("user_id", value: blockedId)
            }
            return try await filteredQuery.execute().value
        } else {
            return try await query.execute().value
        }
    } else {
        return try await supabase
            .from("user_profiles")
            .select()
            .execute()
            .value
    }
    }

    func searchProfiles(keyword: String, excludingUserId: UUID?) async throws -> [UserProfile] {
        if let userId = excludingUserId {
            // 1. 먼저 차단한 사용자 ID 목록을 가져옴
            let blockedUsers: [Block] = try await supabase
                .from("blocks")
                .select()
                .eq("reporter_id", value: userId.uuidString)
                .execute()
                .value
            
            let blockedUserIds = blockedUsers.map { $0.blockedUserId.uuidString }
            
            // 2. 차단된 사용자를 제외한 프로필 검색
            let query = supabase
                .from("user_profiles")
                .select()
                .ilike("name", value: "%\(keyword)%")
                .neq("user_id", value: userId.uuidString)  // 자신 제외
            
            if !blockedUserIds.isEmpty {
                // 수정된 부분: 각 차단된 ID에 대해 개별적으로 neq 필터 적용
                var filteredQuery = query
                for blockedId in blockedUserIds {
                    filteredQuery = filteredQuery.neq("user_id", value: blockedId)
                }
                return try await filteredQuery.execute().value
            } else {
                return try await query.execute().value
            }
        } else {
            return try await supabase
                .from("user_profiles")
                .select()
                .ilike("name", value: "%\(keyword)%")
                .execute()
                .value
        }
    }
    
    func blockUser(reporterId: UUID, blockedUserId: UUID) async throws {
        let blockData = Block(
            id: UUID(),
            reporterId: reporterId,
            blockedUserId: blockedUserId,
            createdAt: Date()
        )
        
        try await supabase
            .from("blocks")
            .insert(blockData)
            .execute()
    }

    func currentUserId() -> UUID? {
        return supabase.auth.currentUser?.id
    }

    func fetchBlockedUsers(for userId: UUID) async throws -> [Block] {
        do {
            let blockedUsers: [Block] = try await supabase
                .from("blocks")
                .select()
                .eq("reporter_id", value: userId.uuidString)
                .execute()
                .value
            return blockedUsers
        } catch {
            Logger.error("Failed to fetch blocked users: \(error.localizedDescription)")
            throw error
        }
    }
    
    func unblockUser(reporterId: UUID, blockedUserId: UUID) async throws {
        do {
            try await supabase
                .from("blocks")
                .delete()
                .eq("reporter_id", value: reporterId.uuidString)
                .eq("blocked_user_id", value: blockedUserId.uuidString)
                .execute()
        } catch {
            Logger.error("Failed to unblock user: \(error.localizedDescription)")
            throw error
        }
    }
}
