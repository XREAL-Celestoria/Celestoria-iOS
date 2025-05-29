//
//  ProfileUseCase.swift
//  Celestoria
//
//  Created by Park Seyoung on 1/20/25.
//

import Foundation
import UIKit

struct ProfileUseCase {
    private let authRepository: AuthRepositoryProtocol
    private let mediaRepository: MediaRepository
    
    init(authRepository: AuthRepositoryProtocol, mediaRepository: MediaRepository) {
        self.authRepository = authRepository
        self.mediaRepository = mediaRepository
    }
    
    func fetchProfile() async throws -> UserProfile {
        try await authRepository.fetchProfile()
    }

    func fetchProfileByUserId(userId: UUID) async throws -> UserProfile {
        try await authRepository.fetchProfileByUserId(userId: userId)
    }
    
    func updateProfile(
        name: String? = nil,
        profileKey: Int? = nil,
        imageData: Data? = nil,
        spaceThumbnailId: String? = nil,
        starfield: String? = nil,
        userId: UUID
    ) async throws -> UserProfile {
        var profileImageURL: String? = nil

        // 커스텀 이미지가 있는 경우에만 업로드
        if let imageData = imageData, let image = UIImage(data: imageData) {
            let (url, _) = try await mediaRepository.uploadProfileImage(image, userId: userId)
            profileImageURL = url
        }

        // 서버에 최종 데이터 전달 (profileKey 포함)
        let updatedProfile = try await authRepository.updateProfile(
            name: name,
            profileImageURL: profileImageURL,
            profileKey: profileKey,
            spaceThumbnailId: spaceThumbnailId,
            starfield: starfield
        )

        return updatedProfile
    }
}
