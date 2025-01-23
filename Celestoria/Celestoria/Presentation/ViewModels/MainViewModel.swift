//
//  MainViewModel.swift
//  Celestoria
//
//  Created by Park Seyoung on 1/20/25.
//

import Foundation

@MainActor
class MainViewModel: ObservableObject {
    @Published var memories: [Memory] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let fetchMemoriesUseCase: FetchMemoriesUseCase
    private let deleteMemoryUseCase: DeleteMemoryUseCase
    
    init(
        fetchMemoriesUseCase: FetchMemoriesUseCase,
        deleteMemoryUseCase: DeleteMemoryUseCase
    ) {
        self.fetchMemoriesUseCase = fetchMemoriesUseCase
        self.deleteMemoryUseCase = deleteMemoryUseCase
    }
    
    func fetchAllMemories() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            memories = try await fetchMemoriesUseCase.executeAll()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    /// Fetch memories for the given user ID
    func fetchMemories(for userId: UUID) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            memories = try await fetchMemoriesUseCase.execute(for: userId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    /// Delete a memory by its ID
    func deleteMemory(_ memoryId: UUID) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await deleteMemoryUseCase.execute(memoryId: memoryId)
            memories.removeAll { $0.id == memoryId }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

