//
//  CreateMemoryUseCase.swift
//  Celestoria
//
//  Created by Park Seyoung on 1/20/25.
//

import Foundation
import Combine

class CreateMemoryUseCase {
    private let memoryRepository: MemoryRepository

    init(memoryRepository: MemoryRepository) {
        self.memoryRepository = memoryRepository
    }

    func execute(memory: Memory) -> AnyPublisher<Void, Error> {
        return memoryRepository.createMemory(memory)
    }
}
