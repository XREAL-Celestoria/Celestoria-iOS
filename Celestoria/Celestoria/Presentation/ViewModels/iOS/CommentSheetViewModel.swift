//
//  CommentSheetViewModel.swift
//  Celestoria
//
//  Created by Seyoung Park on 8/7/25.
//

import Foundation
import SwiftUI
import os

@MainActor
final class CommentSheetViewModel: ObservableObject {
    // MARK: - Dependencies
    private let memory: Memory
    private let diContainer: DIContainer
    private let logger = Logger(subsystem: "Celestoria", category: "CommentSheetViewModel")
    
    // MARK: - Published Properties
    @Published var commentText: String = ""
    @Published var isPosting: Bool = false
    @Published var showError: Bool = false
    @Published var errorMessage: String?
    @Published var comments: [(comment: Comment, userProfile: UserProfile?)] = []
    @Published var isLoadingComments: Bool = false
    @Published var currentUserProfile: UserProfile?
    
    // MARK: - Computed Properties
    var canPost: Bool {
        !commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        commentText.count <= 500 &&
        !isPosting
    }
    
    // MARK: - Initialization
    init(memory: Memory, diContainer: DIContainer) {
        self.memory = memory
        self.diContainer = diContainer
    }
    
    // MARK: - Public Methods
    func loadComments() async {
        isLoadingComments = true
        defer { isLoadingComments = false }
        
        do {
            let commentsWithProfiles = try await diContainer.commentUseCase.fetchCommentsWithProfiles(for: memory.id)
            self.comments = commentsWithProfiles
            logger.info("Loaded \(commentsWithProfiles.count) comments for memory: \(self.memory.id)")
        } catch {
            logger.error("Failed to load comments: \(error.localizedDescription)")
            showError(message: "댓글을 불러오는데 실패했습니다.")
        }
    }
    
    func loadCurrentUserProfile() async {
        guard let currentUserId = diContainer.appState.userId else { return }
        
        do {
            let profile = try await diContainer.profileUseCase.fetchProfileByUserId(userId: currentUserId)
            self.currentUserProfile = profile
        } catch {
            logger.error("Failed to load current user profile: \(error.localizedDescription)")
        }
    }
    
    func postComment() async {
        guard let currentUserId = diContainer.appState.userId else {
            showError(message: "로그인이 필요합니다.")
            return
        }
        
        guard canPost else { return }
        
        isPosting = true
        defer { isPosting = false }
        
        do {
            try await diContainer.commentUseCase.createComment(
                memoryId: memory.id,
                userId: currentUserId,
                content: commentText.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            
            logger.info("Comment posted successfully for memory: \(self.memory.id)")
            
            // Reset comment text
            commentText = ""
            
            // Reload comments to show the new comment
            await loadComments()
            
        } catch {
            logger.error("❌ Failed to post comment")
            logger.error("   Error: \(error)")
            logger.error("   Error type: \(type(of: error))")
            logger.error("   Error description: \(error.localizedDescription)")
            
            // NSError인 경우 추가 정보
            if let nsError = error as NSError? {
                logger.error("   NSError domain: \(nsError.domain)")
                logger.error("   NSError code: \(nsError.code)")
                logger.error("   NSError userInfo: \(nsError.userInfo)")
            }
            
            // 사용자에게 더 구체적인 에러 메시지 표시
            let errorMsg = error.localizedDescription.contains("RLS") 
                ? "권한 문제로 댓글을 작성할 수 없습니다."
                : error.localizedDescription.contains("foreign key")
                ? "메모리를 찾을 수 없습니다."
                : "댓글 작성에 실패했습니다: \(error.localizedDescription)"
            
            showError(message: errorMsg)
        }
    }
    
    func deleteComment(_ commentId: UUID) async {
        do {
            try await diContainer.commentUseCase.deleteComment(commentId: commentId)
            logger.info("Comment deleted successfully: \(commentId)")
            
            // Reload comments to update the list
            await loadComments()
            
        } catch {
            logger.error("Failed to delete comment: \(error.localizedDescription)")
            showError(message: "댓글 삭제에 실패했습니다.")
        }
    }
    
    // MARK: - Private Methods
    private func showError(message: String) {
        errorMessage = message
        showError = true
    }
}
