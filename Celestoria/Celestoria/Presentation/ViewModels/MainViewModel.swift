//
//  MainViewModel.swift
//  Celestoria
//
//  Created by Park Seyoung on 1/20/25.
//

import Foundation
import os

@MainActor
class MainViewModel: ObservableObject {
    private let logger = Logger(subsystem: "com.Celestoria.Celestoria", category: "MainViewModel")
    @Published var memories: [Memory] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var hasLoadedInitialMemories: Bool = false 

    private let fetchMemoriesUseCase: FetchMemoriesUseCase
    private let deleteMemoryUseCase: DeleteMemoryUseCase
    private let spaceCoordinator: SpaceCoordinator
    
    init(
        fetchMemoriesUseCase: FetchMemoriesUseCase,
        deleteMemoryUseCase: DeleteMemoryUseCase,
        spaceCoordinator: SpaceCoordinator
    ) {
        self.fetchMemoriesUseCase = fetchMemoriesUseCase
        self.deleteMemoryUseCase = deleteMemoryUseCase
        self.spaceCoordinator = spaceCoordinator
    }
    
    func fetchAllMemories() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            self.memories = try await fetchMemoriesUseCase.executeAll()
            await spaceCoordinator.setInitialMemories(self.memories)
        } catch {
            logger.error("❌ fetchAllMemories failed: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }
    
    // Fetch memories for the given user ID
    func fetchMemories(for userId: UUID) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let fetched = try await fetchMemoriesUseCase.execute(for: userId)
            self.memories = fetched
            await spaceCoordinator.setInitialMemories(self.memories)
        } catch {
            logger.error("❌ fetchMemories failed: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }
    
    // Delete a memory by its ID
    func deleteMemory(_ memoryId: UUID) async {
        isLoading = true
        defer { isLoading = false }

        // 삭제 대상 메모리 검색
        guard let memory = memories.first(where: { $0.id == memoryId }) else {
            errorMessage = "Memory not found."
            return
        }

        do {
            try await deleteMemoryUseCase.execute(
                memoryId: memoryId,
                videoPath: memory.videoURL,
                thumbnailPath: memory.thumbnailURL
            )
            // 로컬 상태에서 삭제
            memories.removeAll { $0.id == memoryId }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

