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
    
    // Core State
    let appState: AppState
    let appModel: AppModel  // 기존 호환성을 위해 유지
    
    // Additional ViewModels (나중에 필요시 접근)
    let addMemoryMainViewModel: AddMemoryMainViewModel
    let settingViewModel: SettingViewModel
    let galaxyViewModel: GalaxyViewModel
    let exploreViewModel: ExploreViewModel

    // Supabase Client
    let supabaseClient: SupabaseClient

    // Repositories
    let memoryRepository: MemoryRepository
    let mediaRepository: MediaRepository
    let authRepository: AuthRepositoryProtocol

    // Use Cases
    private let fetchMemoriesUseCase: FetchMemoriesUseCase
    private let createMemoryUseCase: CreateMemoryUseCase
    private let deleteMemoryUseCase: DeleteMemoryUseCase
    private let signInWithAppleUseCase: SignInWithAppleUseCase
    private let deleteAccountUseCase: DeleteAccountUseCase
    private let signOutUseCase: SignOutUseCase
    let profileUseCase: ProfileUseCase
    private let exploreUseCase: ExploreUseCase
    private let blockedUsersUseCase: BlockedUsersUseCase

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
        
        // Initialize Repositories
        self.memoryRepository = MemoryRepository(supabase: supabaseClient)
        self.mediaRepository = MediaRepository()
        self.authRepository = AuthRepository(supabase: supabaseClient)

        // Initialize Use Cases
        self.profileUseCase = ProfileUseCase(
            authRepository: authRepository,
            mediaRepository: mediaRepository
        )
        self.fetchMemoriesUseCase = FetchMemoriesUseCase(memoryRepository: memoryRepository)
        self.createMemoryUseCase = CreateMemoryUseCase(memoryRepository: memoryRepository, mediaRepository: mediaRepository)
        self.deleteMemoryUseCase = DeleteMemoryUseCase(memoryRepository: memoryRepository)
        self.signInWithAppleUseCase = SignInWithAppleUseCase(repository: authRepository)
        self.deleteAccountUseCase = DeleteAccountUseCase(repository: authRepository)
        self.signOutUseCase = SignOutUseCase(repository: authRepository)
        self.exploreUseCase = ExploreUseCase(
            authRepository: authRepository,
            memoryRepository: memoryRepository
        )
        self.blockedUsersUseCase = BlockedUsersUseCase(
            authRepository: authRepository
        )

        // 먼저 SpaceCoordinator 초기화
        let spaceCoordinator = SpaceCoordinator(
            appModel: appModel,
            memoryRepository: memoryRepository,
            profileUseCase: profileUseCase
        )

        // 나머지 ViewModels 초기화
        let mainViewModel = MainViewModel(
            fetchMemoriesUseCase: fetchMemoriesUseCase,
            deleteMemoryUseCase: deleteMemoryUseCase,
            spaceCoordinator: spaceCoordinator
        )
        // AppState 초기화 (loginViewModel 없이)
        self.appState = AppState(
            spaceCoordinator: spaceCoordinator,
            mainViewModel: mainViewModel
        )
        
        // LoginViewModel을 AppState와 함께 초기화
        let loginViewModel = LoginViewModel(
            signInUseCase: signInWithAppleUseCase,
            profileUseCase: profileUseCase,
            appModel: appModel,
            appState: self.appState
        )
        
        // AppState에 loginViewModel 설정
        self.appState.loginViewModel = loginViewModel
        
        // 기타 ViewModels
        self.exploreViewModel = ExploreViewModel(
            exploreUseCase: exploreUseCase,
            appModel: appModel
        )
        self.addMemoryMainViewModel = AddMemoryMainViewModel(createMemoryUseCase: createMemoryUseCase, appModel: appModel)
        self.settingViewModel = SettingViewModel(
            deleteAccountUseCase: deleteAccountUseCase,
            signOutUseCase: signOutUseCase,
            profileUseCase: profileUseCase,
            blockedUsersUseCase: blockedUsersUseCase,
            appModel: appModel
        )
        self.galaxyViewModel = GalaxyViewModel(
            appModel: appModel,
            spaceCoordinator: spaceCoordinator,
            profileUseCase: profileUseCase
        )

        // 모든 초기화가 끝난 후 자동 로그인 체크
        if let currentUser = self.supabaseClient.auth.currentUser {
            // AppState와 AppModel 모두 업데이트
            self.appState.userId = currentUser.id
            self.appState.activeScreen = .main
            self.appModel.userId = currentUser.id
            self.appModel.activeScreen = .main
            
            Task {
                do {
                    let fetchedProfile = try await profileUseCase.fetchProfile()
                    self.appState.userProfile = fetchedProfile
                    self.appModel.userProfile = fetchedProfile
                } catch {
                    Logger.error("Failed to fetch profile: \(error.localizedDescription)")
                }
            }
        } else {
            // AppState와 AppModel 모두 업데이트
            self.appState.userId = nil
            self.appState.activeScreen = .login
            self.appState.userProfile = nil
            self.appModel.userId = nil
            self.appModel.activeScreen = .login
            self.appModel.userProfile = nil
        }
    }
}
