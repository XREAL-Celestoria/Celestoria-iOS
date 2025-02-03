//
//  MemoryRepository.swift
//  Celestoria
//
//  Created by Park Seyoung on 1/20/25.
//

import Foundation
import Supabase

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