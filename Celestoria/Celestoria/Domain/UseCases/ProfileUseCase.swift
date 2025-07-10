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
        profileKey: Int?? = nil,
        imageData: Data? = nil,
        spaceThumbnailId: String?? = nil,
        starfield: String?? = nil,
        userId: UUID
    ) async throws -> UserProfile {
        let current = try await authRepository.fetchProfileByUserId(userId: userId)

        var profileImageURL: String?

        if let imageData = imageData, let image = UIImage(data: imageData) {
            let (url, _) = try await mediaRepository.uploadProfileImage(image, userId: userId)
            profileImageURL = url
        }
        else if let profileKey = profileKey, profileKey != nil {
            profileImageURL = nil
        }
        else {
            profileImageURL = current.profileImageURL
        }

        return try await authRepository.updateProfile(
            name: name ?? current.name,
            profileImageURL: profileImageURL,
            profileKey: profileKey != nil ? profileKey! : current.profileKey,
            spaceThumbnailId: spaceThumbnailId != nil ? spaceThumbnailId! : current.spaceThumbnailId,
            starfield: starfield ?? current.starfield
        )
    }
}
