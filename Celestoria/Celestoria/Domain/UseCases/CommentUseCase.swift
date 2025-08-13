//
//  CommentUseCase.swift
//  Celestoria
//
//  Created by Minjun Kim on 8/13/25.
//


//
//  CommentUseCase.swift
//  Celestoria
//
//  Created by AI Assistant on 8/12/25.
//

import Foundation
import os

// MARK: - Comment Notification Names
extension Foundation.Notification.Name {
    static let commentAdded = Foundation.Notification.Name("commentAdded")
    static let commentUpdated = Foundation.Notification.Name("commentUpdated")
    static let commentDeleted = Foundation.Notification.Name("commentDeleted")
    static let likeAdded = Foundation.Notification.Name("likeAdded")
    static let likeRemoved = Foundation.Notification.Name("likeRemoved")
}

// MARK: - Comment Notification UserInfo Keys
struct CommentNotificationKeys {
    static let memoryId = "memoryId"
    static let commentId = "commentId"
    static let userId = "userId"
}

// Use case for managing comments on memories
class CommentUseCase {
    private let memoryRepository: MemoryRepository
    private let profileUseCase: ProfileUseCase
    private let logger = Logger(subsystem: "com.celestoria", category: "CommentUseCase")
    
    init(memoryRepository: MemoryRepository, profileUseCase: ProfileUseCase) {
        self.memoryRepository = memoryRepository
        self.profileUseCase = profileUseCase
    }
    
    // Create a new comment
    func createComment(memoryId: UUID, userId: UUID, content: String) async throws {
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw CommentError.emptyContent
        }
        
        try await memoryRepository.createComment(memoryId: memoryId, userId: userId, content: content)
        logger.info("Comment created successfully")
        
        // Post notification for comment addition
        NotificationCenter.default.post(
            name: .commentAdded,
            object: nil,
            userInfo: [
                CommentNotificationKeys.memoryId: memoryId,
                CommentNotificationKeys.userId: userId
            ]
        )
    }
    
    // Update an existing comment
    func updateComment(commentId: UUID, newContent: String) async throws {
        guard !newContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw CommentError.emptyContent
        }
        
        // Get the comment to find the memoryId
        guard let comment = try await memoryRepository.fetchComment(id: commentId) else {
            throw CommentError.notFound
        }
        
        try await memoryRepository.updateComment(commentId: commentId, newContent: newContent)
        logger.info("Comment updated successfully")
        
        // Post notification for comment update
        NotificationCenter.default.post(
            name: .commentUpdated,
            object: nil,
            userInfo: [
                CommentNotificationKeys.memoryId: comment.memoryId,
                CommentNotificationKeys.commentId: commentId,
                CommentNotificationKeys.userId: comment.userId
            ]
        )
    }
    
    // Delete a comment
    func deleteComment(commentId: UUID) async throws {
        // Get the comment to find the memoryId before deleting
        guard let comment = try await memoryRepository.fetchComment(id: commentId) else {
            throw CommentError.notFound
        }
        
        try await memoryRepository.deleteComment(commentId: commentId)
        logger.info("Comment deleted successfully")
        
        // Post notification for comment deletion
        NotificationCenter.default.post(
            name: .commentDeleted,
            object: nil,
            userInfo: [
                CommentNotificationKeys.memoryId: comment.memoryId,
                CommentNotificationKeys.commentId: commentId,
                CommentNotificationKeys.userId: comment.userId
            ]
        )
    }
    
    // Fetch comments for a memory with user profiles
    func fetchCommentsWithProfiles(for memoryId: UUID) async throws -> [(comment: Comment, userProfile: UserProfile?)] {
        let comments = try await memoryRepository.fetchComments(for: memoryId)
        
        var commentsWithProfiles: [(Comment, UserProfile?)] = []
        
        for comment in comments {
            do {
                let profile = try await profileUseCase.fetchProfileByUserId(userId: comment.userId)
                commentsWithProfiles.append((comment, profile))
            } catch {
                logger.warning("Failed to fetch profile for user \(comment.userId): \(error)")
                commentsWithProfiles.append((comment, nil))
            }
        }
        
        return commentsWithProfiles
    }
    
    // Get comment count for a memory
    func getCommentCount(for memoryId: UUID) async throws -> Int {
        return try await memoryRepository.getCommentCount(for: memoryId)
    }
}

// Comment-specific errors
enum CommentError: LocalizedError {
    case emptyContent
    case unauthorized
    case notFound
    
    var errorDescription: String? {
        switch self {
        case .emptyContent:
            return "Comment content cannot be empty"
        case .unauthorized:
            return "You are not authorized to perform this action"
        case .notFound:
            return "Comment not found"
        }
    }
}