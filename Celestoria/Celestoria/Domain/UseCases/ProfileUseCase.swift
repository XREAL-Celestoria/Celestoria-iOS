//
//  ProfileUseCase.swift
//  Celestoria
//
//  Created by Minjun Kim on 1/27/25.
//

import Foundation
import UIKit

class ProfileUseCase {
    private let authRepository: AuthRepositoryProtocol
    private let mediaRepository: MediaRepository
    
    init(authRepository: AuthRepositoryProtocol, mediaRepository: MediaRepository) {
        self.authRepository = authRepository
        self.mediaRepository = mediaRepository
    }
    
    func updateProfile(name: String?, image: UIImage?, spaceThumbnailId: String? = nil) async throws -> UserProfile {
        var profileImageURL: String? = nil
        
        if let image = image {
            profileImageURL = try await mediaRepository.uploadProfileImage(image).url
        }
        
        return try await authRepository.updateProfile(
            name: name,
            profileImageURL: profileImageURL,
            spaceThumbnailId: spaceThumbnailId
        )
    }
    
    func fetchProfile() async throws -> UserProfile {
        return try await authRepository.fetchProfile()
    }
}
