//
//  AuthRepository.swift
//  Celestoria
//
//  Created by Park Seyoung on 1/20/25.
//

import Foundation
import Supabase

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
        
        if existingProfile.isEmpty {
            // 랜덤 유저네임 생성 (예: User_1234)
            let randomSuffix = String(format: "%04d", Int.random(in: 1000...9999))
            let username = "User_\(randomSuffix)"
            
            let profile = UserProfile(
                id: UUID(),
                userId: userId,
                name: username,
                profileImageURL: nil,
                spaceThumbnailId: "1",
                createdAt: Date()
            )
            
            // ON CONFLICT DO NOTHING 옵션으로 안전하게 삽입
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
    }
}
