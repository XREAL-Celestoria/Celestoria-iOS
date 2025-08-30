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
    
    // Additional ViewModels (필요시 접근)
    #if os(visionOS)
    let addMemoryMainViewModel: AddMemoryMainViewModel
    let galaxyViewModel: GalaxyViewModel
    lazy var exploreViewModel: ExploreViewModel = {
        ExploreViewModel(
            exploreUseCase: self.exploreUseCase,
            appState: self.appState,
            diContainer: self
        )
    }()
    #endif
    let settingViewModel: SettingViewModel

    // Supabase Client
    let supabaseClient: SupabaseClient

    // Repositories
    let memoryRepository: MemoryRepository
    let mediaRepository: MediaRepository
    let authRepository: AuthRepositoryProtocol
    let notificationRepository: NotificationRepository

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
    let commentUseCase: CommentUseCase
    let notificationUseCase: NotificationUseCase

    init() {
        Logger.info("Initializing DIContainer...")

        // --- Supabase Client ---
        let supabaseClient = SupabaseClient(
            supabaseURL: Config.supabaseURL,
            supabaseKey: Config.supabaseAnonKey,
            options: SupabaseClientOptions(
                auth: SupabaseClientOptions.AuthOptions(
                    redirectToURL: URL(string: "com.Celestoria.Celestoria://login-callback"),
                    autoRefreshToken: true
                )
            )
        )
        self.supabaseClient = supabaseClient
        
        // --- Repositories ---
        let memoryRepository = MemoryRepository(supabase: supabaseClient)
        let mediaRepository = MediaRepository()
        let authRepository = AuthRepository(supabase: supabaseClient)
        let notificationRepository = NotificationRepository(supabase: supabaseClient)
        
        self.memoryRepository = memoryRepository
        self.mediaRepository = mediaRepository
        self.authRepository = authRepository
        self.notificationRepository = notificationRepository

        // --- Use Cases ---
        let profileUseCase = ProfileUseCase(authRepository: authRepository, mediaRepository: mediaRepository)
        let fetchMemoriesUseCase = FetchMemoriesUseCase(memoryRepository: memoryRepository)
        let createMemoryUseCase = CreateMemoryUseCase(memoryRepository: memoryRepository, mediaRepository: mediaRepository)
        let deleteMemoryUseCase = DeleteMemoryUseCase(memoryRepository: memoryRepository)
        let signInWithAppleUseCase = SignInWithAppleUseCase(repository: authRepository)
        let deleteAccountUseCase = DeleteAccountUseCase(repository: authRepository)
        let signOutUseCase = SignOutUseCase(repository: authRepository)
        let exploreUseCase = ExploreUseCase(authRepository: authRepository, memoryRepository: memoryRepository)
        let blockedUsersUseCase = BlockedUsersUseCase(authRepository: authRepository)
        
        let commentUseCase = CommentUseCase(memoryRepository: memoryRepository, profileUseCase: profileUseCase)
        let notificationUseCase = NotificationUseCase(
            notificationRepository: notificationRepository,
            profileUseCase: profileUseCase,
            memoryRepository: memoryRepository
        )

        self.profileUseCase = profileUseCase
        self.fetchMemoriesUseCase = fetchMemoriesUseCase
        self.createMemoryUseCase = createMemoryUseCase
        self.deleteMemoryUseCase = deleteMemoryUseCase
        self.signInWithAppleUseCase = signInWithAppleUseCase
        self.deleteAccountUseCase = deleteAccountUseCase
        self.signOutUseCase = signOutUseCase
        self.exploreUseCase = exploreUseCase
        self.blockedUsersUseCase = blockedUsersUseCase
        self.memoryUseCase = fetchMemoriesUseCase
        self.commentUseCase = commentUseCase
        self.notificationUseCase = notificationUseCase

        // --- AppState ---
        #if os(visionOS)
        let spaceCoordinator = SpaceCoordinator(memoryRepository: memoryRepository, profileUseCase: profileUseCase)
        let mainViewModel = MainViewModel(
            fetchMemoriesUseCase: fetchMemoriesUseCase,
            deleteMemoryUseCase: deleteMemoryUseCase,
            spaceCoordinator: spaceCoordinator
        )
        self.appState = AppState(spaceCoordinator: spaceCoordinator, mainViewModel: mainViewModel)
        spaceCoordinator.appState = self.appState
        #else
        self.appState = AppState()
        #endif
        
        // --- LoginViewModel ---
        let loginViewModel = LoginViewModel(
            signInUseCase: signInWithAppleUseCase,
            profileUseCase: profileUseCase,
            appState: self.appState
        )
        self.appState.loginViewModel = loginViewModel
        
        // --- visionOS ViewModels ---
        #if os(visionOS)
        self.addMemoryMainViewModel = AddMemoryMainViewModel(createMemoryUseCase: createMemoryUseCase, appState: self.appState)
        self.galaxyViewModel = GalaxyViewModel(
            appState: self.appState,
            spaceCoordinator: spaceCoordinator,
            profileUseCase: profileUseCase,
            memoryUseCase: fetchMemoriesUseCase
        )
        #endif
        
        // --- SettingViewModel ---
        self.settingViewModel = SettingViewModel(
            deleteAccountUseCase: deleteAccountUseCase,
            signOutUseCase: signOutUseCase,
            profileUseCase: profileUseCase,
            blockedUsersUseCase: blockedUsersUseCase,
            appState: self.appState
        )

        // --- 앱 첫 실행 체크 ---
        let isFirstLaunch = !UserDefaults.standard.bool(forKey: "hasLaunchedBefore")
        if isFirstLaunch {
            UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
            UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
            UserDefaults.standard.removeObject(forKey: "hasAcceptedTerms")
            let supabaseClient = supabaseClient
            Task {
                try? await supabaseClient.auth.signOut()
                Logger.info("First launch detected: cleared any existing session and UserDefaults")
            }
        }

        // --- 자동 로그인 체크 ---
        if !isFirstLaunch, let currentUser = supabaseClient.auth.currentUser {
            appState.userId = currentUser.id
            appState.galaxyTargetUserId = currentUser.id
            let hasAcceptedTerms = UserDefaults.standard.bool(forKey: "hasAcceptedTerms")

            #if os(visionOS)
            appState.activeScreen = .main
            #else
            UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
            appState.hasCompletedOnboarding = true
            appState.hasAcceptedTerms = hasAcceptedTerms
            appState.navigationState = hasAcceptedTerms ? .main : .terms
            #endif

            let profileUseCase = profileUseCase
            let appState = appState

            Task {
                do {
                    let fetchedProfile = try await profileUseCase.fetchProfile()
                    appState.userProfile = fetchedProfile
                    if hasAcceptedTerms, let profileImageURL = fetchedProfile.profileImageURL {
                        await ImageCache.shared.preloadProfileImage(urlString: profileImageURL)
                        Logger.info("DIContainer: Preloaded profile image for returning user")
                    }
                } catch {
                    Logger.error("Failed to fetch profile: \(error.localizedDescription)")
                }
            }
        } else {
            appState.userId = nil
            appState.userProfile = nil
            #if os(visionOS)
            appState.activeScreen = .login
            #else
            let hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
            appState.hasCompletedOnboarding = hasCompletedOnboarding
            appState.hasAcceptedTerms = UserDefaults.standard.bool(forKey: "hasAcceptedTerms")
            appState.navigationState = hasCompletedOnboarding ? .login : .onboarding
            #endif
        }
    }
    
    // --- iOS용 팩토리 메서드 ---
    #if !os(visionOS)
    func makeGalaxyViewModel() -> GalaxyViewModel {
        GalaxyViewModel(appState: appState, profileUseCase: profileUseCase, memoryUseCase: fetchMemoriesUseCase)
    }
    
    func makeiOS3DGalaxyViewModel() -> iOS3DGalaxyViewModel {
        iOS3DGalaxyViewModel(galaxyViewModel: makeGalaxyViewModel(), appState: appState, diContainer: self)
    }
    
    func makeUserInfoModalViewModel(userId: UUID) -> UserInfoModalViewModel {
        UserInfoModalViewModel(userId: userId, diContainer: self)
    }
    
    func makeAddMemoryMainViewModel() -> AddMemoryMainViewModel {
        AddMemoryMainViewModel(createMemoryUseCase: createMemoryUseCase, appState: appState)
    }
    
    func makeExploreViewModel() -> ExploreViewModel {
        ExploreViewModel(exploreUseCase: exploreUseCase, appState: appState, diContainer: self)
    }
    #endif
}
