//
//  DeleteMemoryUseCase.swift
//  Celestoria
//
//  Created by Park Seyoung on 1/20/25.
//

import Foundation
import Combine

class DeleteMemoryUseCase {
    private let memoryRepository: MemoryRepository
    
    init(memoryRepository: MemoryRepository) {
        self.memoryRepository = memoryRepository
    }
    
    func execute(memoryId: UUID) -> AnyPublisher<Void, Error> {
        return memoryRepository.deleteMemory(memoryId)
    }
}
