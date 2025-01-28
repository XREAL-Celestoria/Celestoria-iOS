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
        self.mediaRepository = MediaRepository(supabase: supabaseClient)
        self.authRepository = AuthRepository(supabase: supabaseClient)

        // Initialize Use Cases
        self.fetchMemoriesUseCase = FetchMemoriesUseCase(memoryRepository: memoryRepository)
        self.createMemoryUseCase = CreateMemoryUseCase(memoryRepository: memoryRepository, mediaRepository: mediaRepository)
        self.deleteMemoryUseCase = DeleteMemoryUseCase(memoryRepository: memoryRepository)
        self.signInWithAppleUseCase = SignInWithAppleUseCase(repository: authRepository)
        self.deleteAccountUseCase = DeleteAccountUseCase(repository: authRepository)
        self.signOutUseCase = SignOutUseCase(repository: authRepository)
        self.profileUseCase = ProfileUseCase(
            authRepository: authRepository,
            mediaRepository: mediaRepository
        )
        self.exploreUseCase = ExploreUseCase(
            authRepository: authRepository,
            memoryRepository: memoryRepository
        )

        // Initialize ViewModels and Coordinators
         self.spaceCoordinator = SpaceCoordinator(
            appModel: appModel,
            memoryRepository: memoryRepository,
            profileUseCase: profileUseCase
        )
        self.mainViewModel = MainViewModel(
            fetchMemoriesUseCase: fetchMemoriesUseCase,
            deleteMemoryUseCase: deleteMemoryUseCase,
            spaceCoordinator: spaceCoordinator
        )
        self.exploreViewModel = ExploreViewModel(
            exploreUseCase: exploreUseCase,
            appModel: appModel
        )
        self.loginViewModel = LoginViewModel(signInUseCase: signInWithAppleUseCase)
        self.addMemoryMainViewModel = AddMemoryMainViewModel(createMemoryUseCase: createMemoryUseCase, appModel: appModel)
        self.settingViewModel = SettingViewModel(
            deleteAccountUseCase: deleteAccountUseCase,
            signOutUseCase: signOutUseCase,
            profileUseCase: profileUseCase,
            appModel: appModel
        )
        self.galaxyViewModel = GalaxyViewModel(
            appModel: appModel,
            spaceCoordinator: spaceCoordinator,
            profileUseCase: profileUseCase
        )

        // 자동 로그인 체크
        if let currentUser = self.supabaseClient.auth.currentUser {
            // 세션 존재 -> 이미 로그인 상태
            self.appModel.userId = currentUser.id
            self.appModel.activeScreen = .main
            
            // DB에서 프로필 조회하여 appModel.userProfile에 넣기
            Task {
                do {
                    let fetchedProfile = try await profileUseCase.fetchProfile()
                    appModel.userProfile = fetchedProfile
                } catch {
                    Logger.error("Failed to fetch profile: \(error.localizedDescription)")
                }
            }
            
        } else {
            // 세션 없음 -> 비로그인
            self.appModel.userId = nil
            self.appModel.activeScreen = .login
            // ★ 비로그인 상태니까 userProfile = nil => selectedStarfield = .GRAY
            self.appModel.userProfile = nil
        }
    }
}
