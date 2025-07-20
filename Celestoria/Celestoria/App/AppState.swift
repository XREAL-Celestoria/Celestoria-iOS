//
//  AppState.swift
//  Celestoria
//
//  Created by Minjun Kim on 7/15/25.
//


//
//  AppState.swift
//  Celestoria
//
//  Created by Assistant on 1/16/25.
//

import SwiftUI
import os

/// 앱 전체 상태를 관리하는 통합 객체
@MainActor
final class AppState: ObservableObject {
    // Core State
    @Published var userId: UUID? {
        didSet {
            Logger.info("User ID changed: \(String(describing: userId))")
        }
    }
    @Published var userProfile: UserProfile? {
        didSet {
            // userProfile가 업데이트될 때 starfield 동기화
            if let sfName = userProfile?.starfield,
               let starfieldEnum = StarField(imageName: sfName) {
                self.selectedStarfield = starfieldEnum
            } else {
                // 로그인 안되거나 starfield가 없다면 Gray로 고정
                self.selectedStarfield = .FIELD_1
            }
        }
    }
    @Published var activeScreen: ActiveScreen = .login {
        didSet {
            Logger.info("Active Screen changed: \(activeScreen)")
        }
    }
    
    // UI State
    @Published var showAddMemoryView = false {
        didSet {
            Logger.info("showAddMemoryView : \(showAddMemoryView)")
        }
    }
    @Published var selectedStarfield: StarField? = .FIELD_1 {
        didSet {
            if let starfield = selectedStarfield {
                Logger.info("Starfield Changed: \(starfield.rawValue)")
            } else {
                Logger.info("Starfield Changed: nil")
            }
        }
    }
    @Published var addMemoryScreen: AddMemoryScreen = .main {
        didSet {
            Logger.info("Add Memory - Active Screen changed: \(activeScreen)")
        }
    }
    @Published var showExploreNavigatorView = false {
        didSet {
            Logger.info("showExploreNavigatorView : \(showExploreNavigatorView)")
        }
    }
    @Published var hasAcceptedTerms = false {
        didSet {
            Logger.info("Terms Accepted: \(hasAcceptedTerms)")
        }
    }
    @Published var hasCompletedOnboarding = false {
        didSet {
            Logger.info("Onboarding Completed: \(hasCompletedOnboarding)")
        }
    }
    @Published var navigationState: NavigationState = .onboarding {
        didSet {
            Logger.info("Navigation State changed: \(navigationState)")
        }
    }
    @Published var mainWindowActive: Bool = true  // 메인 윈도우 활성 상태를 추적
    
    // Galaxy Navigation
    @Published var galaxyTargetUserId: UUID? {
        didSet {
            Logger.info("Galaxy Target User ID changed: \(String(describing: galaxyTargetUserId))")
        }
    }
    
    var currentUserId: UUID? {
        return userId
    }
    
    // Immersive Space
    #if os(visionOS)
    let immersiveSpaceID = "SpaceEnvironment"
    @Published var isImmersiveViewActive = false {
        didSet {
            Logger.info("Immersive View Active: \(isImmersiveViewActive)")
        }
    }
    
    // ViewModels (주요 뷰모델만 포함)
    let spaceCoordinator: SpaceCoordinator?
    let mainViewModel: MainViewModel?
    #else
    // iOS doesn't need these properties
    #endif
    var loginViewModel: LoginViewModel?
    
    private let logger = Logger(subsystem: "Celestoria", category: "AppState")
    
    #if os(visionOS)
    init(
        spaceCoordinator: SpaceCoordinator? = nil,
        mainViewModel: MainViewModel? = nil
    ) {
        self.spaceCoordinator = spaceCoordinator
        self.mainViewModel = mainViewModel
        
        // 초기화 확인 로그
        if spaceCoordinator == nil {
            logger.warning("AppState initialized without spaceCoordinator")
        }
        if mainViewModel == nil {
            logger.warning("AppState initialized without mainViewModel")
        }
    }
    #else
    init() {
        // iOS는 추가 초기화 불필요
    }
    #endif
    
    // MARK: - Computed Properties
    
    var isAuthenticated: Bool {
        userId != nil
    }
    
    // MARK: - Methods
    
    func signOut() {
        userId = nil
        userProfile = nil
        activeScreen = .login
        logger.info("User signed out")
    }
    
    func setUser(_ user: UserProfile, userId: UUID) {
        self.userProfile = user
        self.userId = userId
        self.activeScreen = .main
        logger.info("User set: \(userId)")
    }
}