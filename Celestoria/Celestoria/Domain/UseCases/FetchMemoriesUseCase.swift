//
//  FetchMemoriesUseCase.swift
//  Celestoria
//
//  Created by Park Seyoung on 1/20/25.
//

import Foundation

class FetchMemoriesUseCase {
    private let memoryRepository: MemoryRepository

    init(memoryRepository: MemoryRepository) {
        self.memoryRepository = memoryRepository
    }
    
    func executeAll() async throws -> [Memory] {
        return try await memoryRepository.fetchAllMemories()
    }

    func execute(for userId: UUID) async throws -> [Memory] {
        return try await memoryRepository.fetchMemories(for: userId)
    }
}

