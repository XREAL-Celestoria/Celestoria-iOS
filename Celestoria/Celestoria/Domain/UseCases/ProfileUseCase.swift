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
        image: UIImage? = nil,
        spaceThumbnailId: String? = nil,
        starfield: String? = nil
    ) async throws -> UserProfile {
        var profileImageURL: String? = nil
        
        // 프로필 이미지가 있으면 업로드
        if let image = image {
            let (url, _) = try await mediaRepository.uploadProfileImage(image)
            profileImageURL = url
        }
        
        // 수정 사항 DB 업데이트
        let updatedProfile = try await authRepository.updateProfile(
            name: name,
            profileImageURL: profileImageURL,
            spaceThumbnailId: spaceThumbnailId,
            starfield: starfield
        )
        
        return updatedProfile
    }
}
