//
//  iOSMemoryDetailViewModel.swift
//  Celestoria
//
//  Created by Seyoung Park on 8/7/25.
//

import Foundation
import SwiftUI
import os
import Combine

@MainActor
final class iOSMemoryDetailViewModel: ObservableObject {
    // MARK: - Dependencies
    private let memory: Memory
    private let diContainer: DIContainer
    private let logger = Logger(subsystem: "Celestoria", category: "iOSMemoryDetailViewModel")
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Published Properties
    @Published var userProfile: UserProfile?
    @Published var likeCount: Int = 0
    @Published var isLiked: Bool = false
    @Published var commentCount: Int = 0
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false
    @Published var showDeleteAlert: Bool = false
    
    // MARK: - Computed Properties
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: memory.createdAt)
    }
    
    var isOwner: Bool {
        guard let appState = appState else { return false }
        return memory.userId == appState.userId
    }
    
    var canLike: Bool {
        guard let currentUserId = appState?.userId else { return false }
        return memory.userId != currentUserId
    }
    
    private var appState: AppState? {
        diContainer.appState
    }
    
    // MARK: - Initialization
    init(memory: Memory, diContainer: DIContainer) {
        self.memory = memory
        self.diContainer = diContainer
        
        setupCommentNotifications()
    }
    
    deinit {
        cancellables.removeAll()
    }
    
    // MARK: - Public Methods
    func loadData() async {
        async let profileTask = loadUserProfile()
        async let likeDataTask = loadLikeData()
        async let commentCountTask = loadCommentCount()
        
        await profileTask
        await likeDataTask
        await commentCountTask
    }
    
    func toggleLike() async {
        guard let appState = appState,
              let currentUserId = appState.userId else { return }
        
        do {
            if isLiked {
                // 좋아요 제거
                try await diContainer.memoryRepository.deleteLike(memoryId: memory.id, userId: currentUserId)
                likeCount -= 1
                isLiked = false
                logger.info("Like removed for memory: \(self.memory.id)")
                
                NotificationCenter.default.post(name: .likeRemoved, object: nil, userInfo: [
                    CommentNotificationKeys.memoryId: memory.id,
                    CommentNotificationKeys.userId: currentUserId
                ])
            } else {
                // 좋아요 추가
                try await diContainer.memoryRepository.createLike(memoryId: memory.id, userId: currentUserId)
                likeCount += 1
                isLiked = true
                logger.info("Like added for memory: \(self.memory.id)")
                
                NotificationCenter.default.post(name: .likeAdded, object: nil, userInfo: [
                    CommentNotificationKeys.memoryId: memory.id,
                    CommentNotificationKeys.userId: currentUserId
                ])
            }
        } catch {
            logger.error("Failed to toggle like: \(error.localizedDescription)")
            errorMessage = "좋아요 처리 중 오류가 발생했습니다."
        }
    }
    
    func showDeleteConfirmation() {
        showDeleteAlert = true
    }
    
    func deleteMemory() async -> Bool {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let videoPath = extractPathFromURL(memory.videoURL)
            let thumbnailPath = extractPathFromURL(memory.thumbnailURL)
            try await diContainer.deleteMemoryUseCase.execute(
                memoryId: memory.id,
                videoPath: videoPath,
                thumbnailPath: thumbnailPath
            )
            
            // Notify main view to refresh
            diContainer.appState.refreshMainView = true
            logger.info("Memory successfully deleted: \(self.memory.id.uuidString)")
            return true
        } catch {
            logger.error("Error deleting memory: \(error.localizedDescription)")
            self.errorMessage = "An error occurred while deleting the memory."
            return false
        }
    }
    
    func clearError() {
        errorMessage = nil
    }
    
    // MARK: - Private Methods
    private func loadUserProfile() async {
        do {
            let profile = try await diContainer.profileUseCase.fetchProfileByUserId(userId: memory.userId)
            self.userProfile = profile
        } catch {
            logger.error("Error loading user profile: \(error.localizedDescription)")
            self.errorMessage = "Failed to load user profile."
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
    
    private func loadCommentCount() async {
        do {
            let count = try await diContainer.memoryRepository.getCommentCount(for: memory.id)
            self.commentCount = count
        } catch {
            logger.error("Error loading comment count: \(error.localizedDescription)")
        }
    }
    
    private func setupCommentNotifications() {
        // Listen for comment additions
        NotificationCenter.default.publisher(for: .commentAdded)
            .sink { [weak self] notification in
                guard let self = self,
                      let memoryId = notification.userInfo?[CommentNotificationKeys.memoryId] as? UUID,
                      memoryId == self.memory.id else { return }
                
                Task { @MainActor in
                    await self.loadCommentCount()
                }
            }
            .store(in: &cancellables)
        
        // Listen for comment updates
        NotificationCenter.default.publisher(for: .commentUpdated)
            .sink { [weak self] notification in
                guard let self = self,
                      let memoryId = notification.userInfo?[CommentNotificationKeys.memoryId] as? UUID,
                      memoryId == self.memory.id else { return }
                
                Task { @MainActor in
                    await self.loadCommentCount()
                }
            }
            .store(in: &cancellables)
        
        // Listen for comment deletions
        NotificationCenter.default.publisher(for: .commentDeleted)
            .sink { [weak self] notification in
                guard let self = self,
                      let memoryId = notification.userInfo?[CommentNotificationKeys.memoryId] as? UUID,
                      memoryId == self.memory.id else { return }
                
                Task { @MainActor in
                    await self.loadCommentCount()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Helpers
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
    
    // Compatibility no-op (legacy API)
    func setup(appState: AppState) { }
}

