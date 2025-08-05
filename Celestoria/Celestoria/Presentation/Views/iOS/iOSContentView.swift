//
//  iOSContentView.swift
//  Celestoria
//
//  Created by Minjun Kim on 7/20/25.
//

import SwiftUI

struct iOSContentView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var loginViewModel: LoginViewModel
    @EnvironmentObject var settingViewModel: SettingViewModel
    let diContainer: DIContainer
    @State private var showSplash = true
    
    init(diContainer: DIContainer) {
        self.diContainer = diContainer
    }
    
    var body: some View {
        ZStack {
            // 메인 컨텐츠
            currentView
            
            // 스플래시 오버레이 (앱 시작 시 0.5초만)
            if showSplash {
                iOSSplashView()
                    .transition(.opacity)
            }
        }
        .onAppear {
            initializeApp()
        }
    }
    
    @ViewBuilder
    private var currentView: some View {
        switch appState.navigationState {
        case .onboarding:
            iOSOnboardingView()
            
        case .login:
            iOSLoginView()
                .environmentObject(loginViewModel)
            
        case .terms:
            iOSTermsAndConditionsView()
            
        case .initializing:
            iOSUnifiedLoadingView.appInitializing()
                .onAppear {
                    // 2초 후 메인으로 이동
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        appState.isGalaxyLoadingComplete = false
                        appState.navigationState = .main
                    }
                }
            
        case .main:
                // 갤럭시 뷰 (항상 보이게)
                NavigationView {
                    iOS3DGalaxyContainerView(diContainer: diContainer)
                        .navigationBarHidden(true)
                }
                .navigationViewStyle(StackNavigationViewStyle())
                .environmentObject(settingViewModel)
                .onAppear {
                    if appState.galaxyTargetUserId == nil {
                        appState.galaxyTargetUserId = appState.currentUserId
                    }
                }
                
                // 로딩 중일 때만 갤럭시뷰 위에 블러 오버레이
                if !appState.isGalaxyLoadingComplete {
                    iOSUnifiedLoadingView.stars()
                }

        }
    }
    
    private func initializeApp() {
        // 0.5초 스플래시 표시 후 숨김
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeOut(duration: 0.3)) {
                showSplash = false
            }
            
            // 스플래시 후 적절한 화면으로 이동
            determineInitialScreen()
        }
    }
    
    private func determineInitialScreen() {
        if appState.userId != nil {
            // 기존 로그인된 사용자 -> 바로 메인 (갤럭시 로딩 포함)
            appState.isGalaxyLoadingComplete = false
            appState.navigationState = .main
        } else {
            // 신규 사용자 -> 온보딩 플로우
            let hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
            appState.hasCompletedOnboarding = hasCompletedOnboarding
            appState.hasAcceptedTerms = UserDefaults.standard.bool(forKey: "hasAcceptedTerms")
            
            appState.navigationState = hasCompletedOnboarding ? .login : .onboarding
        }
    }
}
