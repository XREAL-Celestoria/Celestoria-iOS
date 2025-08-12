//
//  MemoryRepository.swift
//  Celestoria
//
//  Created by Park Seyoung on 1/20/25.
//

import Foundation
import Supabase
import os

class MemoryRepository {
    private let supabase: SupabaseClient

    init(supabase: SupabaseClient) {
        self.supabase = supabase
    }

    // 특정 유저의 메모리 조회 (숨김처리된 메모리 제외)
    func fetchMemories(for userId: UUID) async throws -> [Memory] {
        try await supabase
            .from("memories")
            .select()
            .eq("user_id", value: userId.uuidString)
            .eq("is_hidden", value: false)  // 숨김처리되지 않은 메모리만 조회
            .execute()
            .value
    }
    
    // 모든 메모리 조회 (숨김처리된 메모리 제외)
    func fetchAllMemories() async throws -> [Memory] {
        try await supabase
            .from("memories")
            .select()
            .eq("is_hidden", value: false)  // 숨김처리되지 않은 메모리만 조회
            .execute()
            .value
    }
    
    // 특정 메모리 조회 (숨김처리된 메모리도 조회 가능 - 관리자용 또는 신고 처리용)
    func fetchMemory(id: UUID) async throws -> Memory? {
        let memories: [Memory] = try await supabase
            .from("memories")
            .select()
            .eq("id", value: id.uuidString)
            .execute()
            .value
        
        return memories.first
    }
    
    func createMemory(_ memory: Memory) async throws {
        try await supabase
            .from("memories")
            .insert(memory)
            .execute()
    }

    func deleteMemory(_ memoryId: UUID) async throws {
        try await supabase
            .from("memories")
            .delete()
            .eq("id", value: memoryId.uuidString)
            .execute()
    }
    
    func deleteStorageFile(bucketName: String, path: String) async throws {
        try await supabase.storage
            .from(bucketName)
            .remove(paths: [path])
    }
    
    // 신고 생성
    func createReport(memoryId: UUID, reporterId: UUID) async throws {
        let report = ContentReport(
            id: UUID(),
            reporterId: reporterId,
            memoryId: memoryId,
            createdAt: Date()
        )
        
        // 1. 신고 생성
        try await supabase
            .from("reports")
            .insert(report)
            .execute()
            
        // 2. 해당 메모리의 총 신고 수 조회
        let reports: [ContentReport] = try await supabase
            .from("reports")
            .select()
            .eq("memory_id", value: memoryId.uuidString)
            .execute()
            .value
            
        // 3. 신고가 3회 이상이면 메모리 숨김 처리
        if reports.count >= 3 {
            try await supabase
                .from("memories")
                .update(["is_hidden": true])
                .eq("id", value: memoryId.uuidString)
                .execute()
        }
    }
    
    // 이미 신고한 메모리인지 확인
    func hasReported(memoryId: UUID, reporterId: UUID) async throws -> Bool {
        let reports: [ContentReport] = try await supabase
            .from("reports")
            .select()
            .eq("memory_id", value: memoryId.uuidString)
            .eq("reporter_id", value: reporterId.uuidString)
            .execute()
            .value
            
        return !reports.isEmpty
    }
    
    // MARK: - 좋아요 관련 메서드
    
    // 좋아요 생성
    func createLike(memoryId: UUID, userId: UUID) async throws {
        let like = Like(
            id: UUID(),
            userId: userId,
            memoryId: memoryId,
            createdAt: Date()
        )
        
        Logger().info("Creating like - userId: \(userId), memoryId: \(memoryId)")
        
        do {
            try await supabase
                .from("likes")
                .insert(like)
                .execute()
            Logger().info("Like created successfully")
        } catch {
            Logger().error("Failed to create like: \(error)")
            throw error
        }
    }
    
    // 좋아요 삭제 (좋아요 취소)
    func deleteLike(memoryId: UUID, userId: UUID) async throws {
        try await supabase
            .from("likes")
            .delete()
            .eq("memory_id", value: memoryId.uuidString)
            .eq("user_id", value: userId.uuidString)
            .execute()
    }
    
    // 특정 메모리의 좋아요 수 조회
    func getLikeCount(for memoryId: UUID) async throws -> Int {
        let likes: [Like] = try await supabase
            .from("likes")
            .select()
            .eq("memory_id", value: memoryId.uuidString)
            .execute()
            .value
            
        return likes.count
    }
    
    // 사용자가 특정 메모리에 좋아요를 눌렀는지 확인
    func hasLiked(memoryId: UUID, userId: UUID) async throws -> Bool {
        let likes: [Like] = try await supabase
            .from("likes")
            .select()
            .eq("memory_id", value: memoryId.uuidString)
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value
            
        return !likes.isEmpty
    }
    
    // MARK: - 댓글 관련 메서드
    
    // 댓글 생성
    func createComment(memoryId: UUID, userId: UUID, content: String) async throws {
        let comment = Comment(userId: userId, memoryId: memoryId, content: content)
        
        Logger().info("Creating comment - userId: \(userId), memoryId: \(memoryId)")
        
        do {
            try await supabase
                .from("comments")
                .insert(comment)
                .execute()
            Logger().info("Comment created successfully")
        } catch {
            Logger().error("Failed to create comment: \(error)")
            throw error
        }
    }
    
    // 댓글 수정
    func updateComment(commentId: UUID, newContent: String) async throws {
        try await supabase
            .from("comments")
            .update(["content": newContent, "updated_at": Date().ISO8601Format()])
            .eq("id", value: commentId.uuidString)
            .execute()
    }
    
    // 댓글 삭제
    func deleteComment(commentId: UUID) async throws {
        try await supabase
            .from("comments")
            .delete()
            .eq("id", value: commentId.uuidString)
            .execute()
    }
    
    // 특정 메모리의 댓글 조회
    func fetchComments(for memoryId: UUID) async throws -> [Comment] {
        let comments: [Comment] = try await supabase
            .from("comments")
            .select()
            .eq("memory_id", value: memoryId.uuidString)
            .order("created_at", ascending: false)
            .execute()
            .value
            
        return comments
    }
    
    // 특정 댓글 조회
    func fetchComment(id: UUID) async throws -> Comment? {
        let comments: [Comment] = try await supabase
            .from("comments")
            .select()
            .eq("id", value: id.uuidString)
            .execute()
            .value
            
        return comments.first
    }
    
    // 특정 메모리의 댓글 수 조회
    func getCommentCount(for memoryId: UUID) async throws -> Int {
        let comments: [Comment] = try await supabase
            .from("comments")
            .select()
            .eq("memory_id", value: memoryId.uuidString)
            .execute()
            .value
            
        return comments.count
    }
    
    // MARK: - URL 토큰 갱신
    
    // 썸네일 URL 토큰 갱신
    func refreshThumbnailURL(for memory: Memory) async throws -> String? {
        guard let thumbnailURL = memory.thumbnailURL else { return nil }
        
        // URL에서 경로 추출
        let path = extractPathFromURL(thumbnailURL)
        guard let path = path else { return nil }
        
        // 새로운 서명된 URL 생성
        let signedURL = try await supabase.storage
            .from("thumbnails")
            .createSignedURL(
                path: path,
                expiresIn: 3600 // 1시간
            )
        
        return signedURL.absoluteString
    }
    
    // 비디오 URL 토큰 갱신
    func refreshVideoURL(for memory: Memory) async throws -> String? {
        guard let videoURL = memory.videoURL else { return nil }
        
        // URL에서 경로 추출
        let path = extractPathFromURL(videoURL)
        guard let path = path else { return nil }
        
        // 새로운 서명된 URL 생성
        let signedURL = try await supabase.storage
            .from("spatial_videos")
            .createSignedURL(
                path: path,
                expiresIn: 3600 // 1시간
            )
        
        return signedURL.absoluteString
    }
    
    // URL에서 경로 추출하는 헬퍼 메서드
    private func extractPathFromURL(_ urlString: String) -> String? {
        guard let url = URL(string: urlString) else {
            print("❌ DEBUG: Invalid URL: \(urlString)")
            return nil
        }
        
        // URL에서 경로 부분만 추출
        // 예: https://.../storage/v1/object/sign/thumbnails/path/to/file?token=...
        // -> thumbnails/path/to/file
        
        let pathComponents = url.pathComponents
        print("🔍 DEBUG: URL path components: \(pathComponents)")
        
        if let signIndex = pathComponents.firstIndex(of: "sign"),
           signIndex + 1 < pathComponents.count {
            let bucketName = pathComponents[signIndex + 1]
            let filePath = pathComponents.dropFirst(signIndex + 2).joined(separator: "/")
            let fullPath = "\(bucketName)/\(filePath)"
            print("🔍 DEBUG: Extracted path: \(fullPath)")
            return fullPath
        }
        
        print("❌ DEBUG: Could not extract path from URL: \(urlString)")
        return nil
    }
}

enum MemoryError: Error, LocalizedError {
    case categoryNotSelected
    case videoNotSelected
    case videoDataEmpty
    case invalidImageData
    case uploadFailed(reason: String)
    
    var errorDescription: String? {
        switch self {
        case .categoryNotSelected:
            return "카테고리를 선택해주세요."
        case .videoNotSelected:
            return "비디오를 선택해주세요."
        case .videoDataEmpty:
            return "비디오 데이터가 없습니다."
        case .invalidImageData:
            return "유효하지 않은 이미지 데이터입니다."
        case .uploadFailed(let reason):
            return "업로드에 실패했습니다: \(reason)"
        }
    }
}