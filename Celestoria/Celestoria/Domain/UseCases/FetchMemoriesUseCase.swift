//
//  FetchMemoriesUseCase.swift
//  Celestoria
//
//  Created by Park Seyoung on 1/20/25.
//

import Foundation
import Combine

class FetchMemoriesUseCase {
    private let memoryRepository: MemoryRepository

    init(memoryRepository: MemoryRepository) {
        self.memoryRepository = memoryRepository
    }

    func execute(for userId: UUID) -> AnyPublisher<[Memory], Error> {
        return memoryRepository.fetchMemories(for: userId)
    }
}
