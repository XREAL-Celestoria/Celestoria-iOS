//
//  MainViewModel.swift
//  Celestoria
//
//  Created by Park Seyoung on 1/20/25.
//
import Foundation
import Combine

@MainActor
class MainViewModel: ObservableObject {
    @Published var memories: [Memory] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    
    private let fetchMemoriesUseCase: FetchMemoriesUseCase
    private let createMemoryUseCase: CreateMemoryUseCase
    private let deleteMemoryUseCase: DeleteMemoryUseCase
    
    init(
        fetchMemoriesUseCase: FetchMemoriesUseCase,
        createMemoryUseCase: CreateMemoryUseCase,
        deleteMemoryUseCase: DeleteMemoryUseCase
    ) {
        self.fetchMemoriesUseCase = fetchMemoriesUseCase
        self.createMemoryUseCase = createMemoryUseCase
        self.deleteMemoryUseCase = deleteMemoryUseCase
    }
    
    func fetchMemories(for userId: UUID) {
        isLoading = true
        fetchMemoriesUseCase.execute(for: userId)
            .receive(on: DispatchQueue.main) 
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            }, receiveValue: { [weak self] memories in
                self?.memories = memories
            })
            .store(in: &cancellables)
    }
    
    func createMemory(_ memory: Memory) {
        isLoading = true
        createMemoryUseCase.execute(memory: memory)
            .receive(on: DispatchQueue.main)  // 메인 스레드에서 처리
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            }, receiveValue: { [weak self] in
                self?.fetchMemories(for: memory.userId)
            })
            .store(in: &cancellables)
    }
    
    func deleteMemory(_ memoryId: UUID) {
        isLoading = true
        deleteMemoryUseCase.execute(memoryId: memoryId)
            .receive(on: DispatchQueue.main)  // 메인 스레드에서 처리
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            }, receiveValue: { [weak self] in
                self?.memories.removeAll { $0.id == memoryId }
            })
            .store(in: &cancellables)
    }
}
