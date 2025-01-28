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
        
        // 프로필이 이미 존재하는지 확인
        let existingProfile: [UserProfile] = try await supabase
            .from("user_profiles")
            .select("*")
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value
        
        // ★ 새 유저인 경우, 랜덤 starfield로 프로필 생성
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

    func updateProfile(
        name: String? = nil,
        profileImageURL: String? = nil,
        spaceThumbnailId: String? = nil,
        starfield: String? = nil
    ) async throws -> UserProfile {
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
        var query = supabase
            .from("user_profiles")
            .select()

        if let userId = excludingUserId {
            query = query.neq("user_id", value: userId.uuidString)
        }

        return try await query.execute().value
    }

    func searchProfiles(keyword: String, excludingUserId: UUID?) async throws -> [UserProfile] {
        var query = supabase
            .from("user_profiles")
            .select()
            .ilike("name", value: "%\(keyword)%")

        if let userId = excludingUserId {
            query = query.neq("user_id", value: userId.uuidString)
        }

        return try await query.execute().value
    }
}
