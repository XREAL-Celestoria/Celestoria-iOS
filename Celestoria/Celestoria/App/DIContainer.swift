//
//  DIContainer.swift
//  Celestoria
//
//  Created by Park Seyoung on 1/16/25.
//

import Foundation
import Supabase
import os
import Auth

@MainActor
final class DIContainer: ObservableObject {
    
    // ViewModels
    let mainViewModel: MainViewModel
    let loginViewModel: LoginViewModel
    let addMemoryMainViewModel: AddMemoryMainViewModel
    let spaceCoordinator: SpaceCoordinator
    let appModel: AppModel
    let settingViewModel: SettingViewModel

    // Supabase Client
    let supabaseClient: SupabaseClient

    // Repositories
    private let memoryRepository: MemoryRepository
    private let mediaRepository: MediaRepository
    private let authRepository: AuthRepositoryProtocol

    // Use Cases
    private let fetchMemoriesUseCase: FetchMemoriesUseCase
    private let createMemoryUseCase: CreateMemoryUseCase
    private let deleteMemoryUseCase: DeleteMemoryUseCase
    private let signInWithAppleUseCase: SignInWithAppleUseCase
    private let deleteAccountUseCase: DeleteAccountUseCase

    init() {
        Logger.info("Initializing DIContainer...")
        self.appModel = AppModel()

        // Initialize Supabase Client
        self.supabaseClient = SupabaseClient(
            supabaseURL: Config.supabaseURL,
            supabaseKey: Config.supabaseAnonKey,
            options: SupabaseClientOptions(
                auth: SupabaseClientOptions.AuthOptions(
                    autoRefreshToken: true
                )
            )
        )
        
        // 자동 로그인 체크
        if let currentUser = self.supabaseClient.auth.currentUser {
            // 세션 존재 -> 이미 로그인 상태
            self.appModel.userId = currentUser.id
            self.appModel.activeScreen = .main
        } else {
            // 세션 없음 -> 로그인 필요
            self.appModel.userId = nil
            self.appModel.activeScreen = .login
        }

        // Initialize Repositories
        self.memoryRepository = MemoryRepository(supabase: supabaseClient)
        self.mediaRepository = MediaRepository(supabase: supabaseClient)
        self.authRepository = AuthRepository(supabase: supabaseClient)

        // Initialize Use Cases
        self.fetchMemoriesUseCase = FetchMemoriesUseCase(memoryRepository: memoryRepository)
        self.createMemoryUseCase = CreateMemoryUseCase(memoryRepository: memoryRepository, mediaRepository: mediaRepository)
        self.deleteMemoryUseCase = DeleteMemoryUseCase(memoryRepository: memoryRepository)
        self.signInWithAppleUseCase = SignInWithAppleUseCase(repository: authRepository)
        self.deleteAccountUseCase = DeleteAccountUseCase(repository: authRepository)

        // Initialize ViewModels and Coordinators
        self.spaceCoordinator = SpaceCoordinator()
        self.mainViewModel = MainViewModel(
            fetchMemoriesUseCase: fetchMemoriesUseCase,
            deleteMemoryUseCase: deleteMemoryUseCase,
            spaceCoordinator: spaceCoordinator
        )
        
        self.loginViewModel = LoginViewModel(signInUseCase: signInWithAppleUseCase)
        self.addMemoryMainViewModel = AddMemoryMainViewModel(createMemoryUseCase: createMemoryUseCase, appModel: appModel)
        self.settingViewModel = SettingViewModel(deleteAccountUseCase: deleteAccountUseCase)
    }
}
