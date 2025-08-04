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
    
    // Additional ViewModels (나중에 필요시 접근)
    #if os(visionOS)
    let addMemoryMainViewModel: AddMemoryMainViewModel
    let galaxyViewModel: GalaxyViewModel
    let exploreViewModel: ExploreViewModel
    #endif
    let settingViewModel: SettingViewModel

    // Supabase Client
    let supabaseClient: SupabaseClient

    // Repositories
    let memoryRepository: MemoryRepository
    let mediaRepository: MediaRepository
    let authRepository: AuthRepositoryProtocol

    // Use Cases
    let fetchMemoriesUseCase: FetchMemoriesUseCase
    private let createMemoryUseCase: CreateMemoryUseCase
    let deleteMemoryUseCase: DeleteMemoryUseCase
    private let signInWithAppleUseCase: SignInWithAppleUseCase
    private let deleteAccountUseCase: DeleteAccountUseCase
    private let signOutUseCase: SignOutUseCase
    let profileUseCase: ProfileUseCase
    private let exploreUseCase: ExploreUseCase
    private let blockedUsersUseCase: BlockedUsersUseCase
    let memoryUseCase: FetchMemoriesUseCase

    init() {
        Logger.info("Initializing DIContainer...")

        // Initialize Supabase Client with basic configuration
        self.supabaseClient = SupabaseClient(
            supabaseURL: Config.supabaseURL,
            supabaseKey: Config.supabaseAnonKey,
            options: SupabaseClientOptions(
                auth: SupabaseClientOptions.AuthOptions(
                    redirectToURL: URL(string: "com.Celestoria.Celestoria://login-callback"),
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
        self.memoryUseCase = self.fetchMemoriesUseCase

        #if os(visionOS)
        // 먼저 SpaceCoordinator와 MainViewModel을 임시로 생성
        let spaceCoordinator = SpaceCoordinator(
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
        
        // SpaceCoordinator에 AppState 연결
        spaceCoordinator.appState = self.appState
        #else
        // iOS에서는 AppState만 초기화
        self.appState = AppState()
        #endif
        
        // LoginViewModel을 AppState와 함께 초기화
        let loginViewModel = LoginViewModel(
            signInUseCase: signInWithAppleUseCase,
            profileUseCase: profileUseCase,
            appState: self.appState
        )
        
        // AppState에 loginViewModel 설정
        self.appState.loginViewModel = loginViewModel
        
        // 기타 ViewModels
        #if os(visionOS)
        self.exploreViewModel = ExploreViewModel(
            exploreUseCase: exploreUseCase,
            appState: self.appState
        )
        self.addMemoryMainViewModel = AddMemoryMainViewModel(createMemoryUseCase: createMemoryUseCase, appState: self.appState)
        self.galaxyViewModel = GalaxyViewModel(
            appState: self.appState,
            spaceCoordinator: spaceCoordinator,
            profileUseCase: profileUseCase,
            memoryUseCase: fetchMemoriesUseCase
        )
        #endif
        
        self.settingViewModel = SettingViewModel(
            deleteAccountUseCase: deleteAccountUseCase,
            signOutUseCase: signOutUseCase,
            profileUseCase: profileUseCase,
            blockedUsersUseCase: blockedUsersUseCase,
            appState: self.appState
        )

        // 모든 초기화가 끝난 후 자동 로그인 체크
        if let currentUser = self.supabaseClient.auth.currentUser {
            // AppState 업데이트
            self.appState.userId = currentUser.id
            self.appState.activeScreen = .main
            
            Task {
                do {
                    let fetchedProfile = try await profileUseCase.fetchProfile()
                    self.appState.userProfile = fetchedProfile
                    
                    // 프로필 이미지 미리 로딩
                    if let profileImageURL = fetchedProfile.profileImageURL {
                        await ImageCache.shared.preloadProfileImage(urlString: profileImageURL)
                        Logger.info("DIContainer: Preloaded profile image for auto-login user")
                    }
                } catch {
                    Logger.error("Failed to fetch profile: \(error.localizedDescription)")
                }
            }
        } else {
            // AppState 업데이트
            self.appState.userId = nil
            self.appState.activeScreen = .login
            self.appState.userProfile = nil
        }
    }
    
    // iOS용 ViewModels 생성 메서드 추가
    #if !os(visionOS)
    func makeGalaxyViewModel() -> GalaxyViewModel {
        return GalaxyViewModel(
            appState: appState,
            profileUseCase: profileUseCase,
            memoryUseCase: fetchMemoriesUseCase
        )
    }
    
    func makeiOS3DGalaxyViewModel() -> iOS3DGalaxyViewModel {
        return iOS3DGalaxyViewModel(
            galaxyViewModel: makeGalaxyViewModel(),
            appState: appState,
            diContainer: self
        )
    }
    
    func makeUserInfoModalViewModel(userId: UUID) -> UserInfoModalViewModel {
        return UserInfoModalViewModel(
            diContainer: self,
            userId: userId
        )
    }
    
    func makeAddMemoryMainViewModel() -> AddMemoryMainViewModel {
        return AddMemoryMainViewModel(
            createMemoryUseCase: createMemoryUseCase,
            appState: appState
        )
    }
    #endif
}
