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
    }
    
    // Update an existing comment
    func updateComment(commentId: UUID, newContent: String) async throws {
        guard !newContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw CommentError.emptyContent
        }
        
        try await memoryRepository.updateComment(commentId: commentId, newContent: newContent)
        logger.info("Comment updated successfully")
    }
    
    // Delete a comment
    func deleteComment(commentId: UUID) async throws {
        try await memoryRepository.deleteComment(commentId: commentId)
        logger.info("Comment deleted successfully")
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