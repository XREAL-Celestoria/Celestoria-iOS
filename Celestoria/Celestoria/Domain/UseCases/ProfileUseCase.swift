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
        let current = try await authRepository.fetchProfileByUserId(userId: userId)

        var profileImageURL: String?
        var finalProfileKey: Int?

        if let imageData = imageData, let image = UIImage(data: imageData) {
            // When uploading custom image, clear the preset key
            let (url, _) = try await mediaRepository.uploadProfileImage(image, userId: userId)
            profileImageURL = url
            finalProfileKey = nil  // Clear preset key when using custom image
        }
        else if profileKey != nil {
            // When preset image is selected, clear custom image URL
            profileImageURL = nil
            finalProfileKey = profileKey
        }
        else {
            // No image change, keep current values
            profileImageURL = current.profileImageURL
            finalProfileKey = current.profileKey
        }

        return try await authRepository.updateProfile(
            name: name ?? current.name,
            profileImageURL: profileImageURL,
            profileKey: finalProfileKey,
            spaceThumbnailId: spaceThumbnailId ?? current.spaceThumbnailId,
            starfield: starfield ?? current.starfield
        )
    }
}
