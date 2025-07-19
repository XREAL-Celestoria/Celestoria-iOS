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
    @Published var userId: UUID?
    @Published var userProfile: UserProfile?
    @Published var activeScreen: ActiveScreen = .login
    
    // UI State
    @Published var showAddMemoryView = false
    @Published var selectedStarfield: StarField? = .FIELD_1
    @Published var addMemoryScreen: AddMemoryScreen = .main
    @Published var showExploreNavigatorView = false
    @Published var hasAcceptedTerms = false
    
    // Immersive Space
    let immersiveSpaceID = "SpaceEnvironment"
    @Published var isImmersiveViewActive = false
    
    // ViewModels (주요 뷰모델만 포함)
    let spaceCoordinator: SpaceCoordinator
    let mainViewModel: MainViewModel
    var loginViewModel: LoginViewModel?
    
    private let logger = Logger(subsystem: "Celestoria", category: "AppState")
    
    init(
        spaceCoordinator: SpaceCoordinator,
        mainViewModel: MainViewModel
    ) {
        self.spaceCoordinator = spaceCoordinator
        self.mainViewModel = mainViewModel
    }
    
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