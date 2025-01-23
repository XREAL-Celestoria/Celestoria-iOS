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

    /// 특정 유저의 메모리
    func fetchMemories(for userId: UUID) async throws -> [Memory] {
        try await supabase
            .from("memories")
            .select("*")
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value
    }

    /// 모든 유저의 메모리
    func fetchAllMemories() async throws -> [Memory] {
        try await supabase
            .from("memories")
            .select("*")
            .execute()
            .value
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

