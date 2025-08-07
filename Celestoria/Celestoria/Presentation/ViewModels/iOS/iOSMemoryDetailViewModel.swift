//
//  iOSMemoryDetailViewModel.swift
//  Celestoria
//
//  Created by Assistant on 1/28/25.
//

import Foundation
import SwiftUI
import os

@MainActor
final class iOSMemoryDetailViewModel: ObservableObject {
    // MARK: - Dependencies
    private let diContainer: DIContainer
    private var appState: AppState?
    private let logger = Logger(subsystem: "Celestoria", category: "iOSMemoryDetailViewModel")
    
    // MARK: - Published Properties
    @Published var memory: Memory
    @Published var userProfile: UserProfile?
    @Published var likeCount: Int = 0
    @Published var isLiked: Bool = false
    @Published var isLikeLoading: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showDeleteAlert: Bool = false
    
    // MARK: - Computed Properties
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd HH:mm"
        return formatter.string(from: memory.createdAt)
    }
    
    var isOwner: Bool {
        memory.userId == appState?.userId
    }
    
    var canLike: Bool {
        !isLikeLoading && memory.userId != appState?.userId
    }
    
    // MARK: - Initialization
    init(memory: Memory, diContainer: DIContainer) {
        self.memory = memory
        self.diContainer = diContainer
    }
    
    // MARK: - Setup
    func setup(appState: AppState) {
        self.appState = appState
    }
    
    // MARK: - Data Loading
    func loadData() async {
        isLoading = true
        defer { isLoading = false }
        
        // Load all data in parallel
        async let profileTask = loadUserProfile()
        async let likeDataTask = loadLikeData()
        
        await profileTask
        await likeDataTask
    }
    
    private func loadUserProfile() async {
        do {
            let profile = try await diContainer.profileUseCase.fetchProfileByUserId(userId: memory.userId)
            self.userProfile = profile
        } catch {
            logger.error("Error loading user profile: \(error.localizedDescription)")
            self.errorMessage = "Failed to load user profile"
        }
    }
    
    private func loadLikeData() async {
        guard let appState = appState,
              let currentUserId = appState.userId else { return }
        
        do {
            // Load like count and current user's like status
            async let likeCountResult = diContainer.memoryRepository.getLikeCount(for: memory.id)
            async let hasLikedResult = diContainer.memoryRepository.hasLiked(memoryId: memory.id, userId: currentUserId)
            
            let (count, liked) = try await (likeCountResult, hasLikedResult)
            
            self.likeCount = count
            self.isLiked = liked
        } catch {
            logger.error("Error loading like data: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Like Functionality
    func toggleLike() async {
        guard let appState = appState,
              let currentUserId = appState.userId else { return }
        guard !isLikeLoading else { return }
        
        // Check if user is trying to like their own memory
        if memory.userId == currentUserId {
            self.errorMessage = "자신의 메모리에는 좋아요를 할 수 없습니다."
            return
        }
        
        isLikeLoading = true
        defer { isLikeLoading = false }
        
        do {
            if isLiked {
                // Unlike
                try await diContainer.memoryRepository.deleteLike(memoryId: memory.id, userId: currentUserId)
                self.likeCount = max(0, self.likeCount - 1)
                self.isLiked = false
            } else {
                // Like
                try await diContainer.memoryRepository.createLike(memoryId: memory.id, userId: currentUserId)
                self.likeCount += 1
                self.isLiked = true
            }
        } catch {
            logger.error("Error toggling like: \(error.localizedDescription)")
            self.errorMessage = "좋아요 처리 중 오류가 발생했습니다."
        }
    }
    
    // MARK: - Delete Functionality
    func showDeleteConfirmation() {
        showDeleteAlert = true
    }
    
    func deleteMemory() async -> Bool {
        guard let appState = appState else { return false }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Extract paths from URLs for file deletion
            let videoPath = extractPathFromURL(memory.videoURL)
            let thumbnailPath = extractPathFromURL(memory.thumbnailURL)
            
            // Delete memory using UseCase
            try await diContainer.deleteMemoryUseCase.execute(
                memoryId: memory.id,
                videoPath: videoPath,
                thumbnailPath: thumbnailPath
            )
            
            // Refresh main view
            appState.refreshMainView = true
            
            logger.info("Memory successfully deleted: \(self.memory.id.uuidString)")
            return true
            
        } catch {
            logger.error("Error deleting memory: \(error.localizedDescription)")
            self.errorMessage = "메모리 삭제 중 오류가 발생했습니다."
            return false
        }
    }
    
    // MARK: - Helper Methods
    private func extractPathFromURL(_ urlString: String?) -> String? {
        guard let urlString = urlString,
              let url = URL(string: urlString) else {
            return nil
        }
        
        let pathComponents = url.pathComponents
        
        // files.applevisionpro.xyz 형식: /celestoria/thumbnails/path/to/file
        if urlString.contains("files.applevisionpro.xyz") {
            if pathComponents.count >= 4 {
                let bucketName = pathComponents[2] // thumbnails 또는 spatial_videos
                let filePath = pathComponents.dropFirst(3).joined(separator: "/")
                return "\(bucketName)/\(filePath)"
            }
        }
        
        // Supabase 형식: /storage/v1/object/sign/thumbnails/path/to/file
        if let signIndex = pathComponents.firstIndex(of: "sign"),
           signIndex + 1 < pathComponents.count {
            let bucketName = pathComponents[signIndex + 1]
            let filePath = pathComponents.dropFirst(signIndex + 2).joined(separator: "/")
            return "\(bucketName)/\(filePath)"
        }
        
        return nil
    }
    
    // MARK: - Error Handling
    func clearError() {
        errorMessage = nil
    }
}
