//
//  DIContainer.swift
//  Celestoria
//
//  Created by Park Seyoung on 1/16/25.
//

// 의존성을 관리하고 주입, 객체 생성 및 관리

import Foundation
import Supabase
import os

@MainActor
final class DIContainer: ObservableObject {
    
    // ViewModels
    let mainViewModel: MainViewModel
    let loginViewModel: LoginViewModel
    let spaceCoordinator: SpaceCoordinator
    let appModel: AppModel

    // Supabase Client
    let supabaseClient: SupabaseClient

    // Repositories
    private let memoryRepository: MemoryRepository
    private let authRepository: AuthRepositoryProtocol

    // Use Cases
    private let fetchMemoriesUseCase: FetchMemoriesUseCase
    private let createMemoryUseCase: CreateMemoryUseCase
    private let deleteMemoryUseCase: DeleteMemoryUseCase
    private let signInWithAppleUseCase: SignInWithAppleUseCase

    init() {
        Logger.info("Initializing DIContainer...")
        self.appModel = AppModel()
        
        // Initialize Supabase Client
        self.supabaseClient = SupabaseClient(
            supabaseURL: Config.supabaseURL,
            supabaseKey: Config.supabaseAnonKey
        )

        // Initialize Repositories
        self.memoryRepository = MemoryRepository(supabase: supabaseClient)
        self.authRepository = AuthRepository(supabase: supabaseClient)

        // Initialize Use Cases
        self.fetchMemoriesUseCase = FetchMemoriesUseCase(memoryRepository: memoryRepository)
        self.createMemoryUseCase = CreateMemoryUseCase(memoryRepository: memoryRepository)
        self.deleteMemoryUseCase = DeleteMemoryUseCase(memoryRepository: memoryRepository)
        self.signInWithAppleUseCase = SignInWithAppleUseCase(repository: authRepository)

        // Initialize ViewModels and Coordinators
        self.mainViewModel = MainViewModel(
            fetchMemoriesUseCase: fetchMemoriesUseCase,
            createMemoryUseCase: createMemoryUseCase,
            deleteMemoryUseCase: deleteMemoryUseCase
        )
        self.loginViewModel = LoginViewModel(signInUseCase: signInWithAppleUseCase)
        self.spaceCoordinator = SpaceCoordinator()
    }
}
