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
    let galaxyViewModel: GalaxyViewModel
    var memoryDetailViewModel: MemoryDetailViewModel?
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
        self.spaceCoordinator = SpaceCoordinator(
            appModel: appModel,
            memoryRepository: memoryRepository,
            profileUseCase: profileUseCase
        )

        // 나머지 ViewModels 초기화
        self.mainViewModel = MainViewModel(
            fetchMemoriesUseCase: fetchMemoriesUseCase,
            deleteMemoryUseCase: deleteMemoryUseCase,
            spaceCoordinator: spaceCoordinator
        )
        self.exploreViewModel = ExploreViewModel(
            exploreUseCase: exploreUseCase,
            appModel: appModel
        )
        self.loginViewModel = LoginViewModel(
            signInUseCase: signInWithAppleUseCase,
            profileUseCase: profileUseCase,
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
            self.appModel.userId = currentUser.id
            self.appModel.activeScreen = .main
            
            Task {
                do {
                    let fetchedProfile = try await profileUseCase.fetchProfile()
                    self.appModel.userProfile = fetchedProfile
                } catch {
                    Logger.error("Failed to fetch profile: \(error.localizedDescription)")
                }
            }
        } else {
            self.appModel.userId = nil
            self.appModel.activeScreen = .login
            self.appModel.userProfile = nil
        }
    }
}
