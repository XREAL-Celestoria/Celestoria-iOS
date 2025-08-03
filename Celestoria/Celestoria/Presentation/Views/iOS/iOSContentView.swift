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
    @State private var galaxyLoadingComplete = false
    @State private var mainViewOpacity: Double = 0
    
    init(diContainer: DIContainer) {
        self.diContainer = diContainer
    }
    
    var body: some View {
        ZStack {
            // 스플래시 화면
            if showSplash {
                iOSSplashView()
                    .transition(.opacity.combined(with: .scale(scale: 1.05)))
                    .zIndex(2)
            }
            
            // 메인 컨텐츠 (스플래시가 true일 때는 투명하게 로드)
            Group {
                switch appState.navigationState {
                case .onboarding:
                    iOSOnboardingView()
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                        .opacity(mainViewOpacity)
                    
                case .login:
                    iOSLoginView()
                        .environmentObject(loginViewModel)
                        .transition(.opacity.combined(with: .move(edge: .trailing)))
                        .opacity(mainViewOpacity)
                    
                case .terms:
                    iOSTermsAndConditionsView()
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                        .zIndex(1)
                        .opacity(mainViewOpacity)
                    
                case .main:
                    NavigationView {
                        iOS3DGalaxyContainerView(diContainer: diContainer)
                            .navigationBarHidden(true)
                    }
                    .navigationViewStyle(StackNavigationViewStyle())
                    .environmentObject(settingViewModel)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    .zIndex(0)
                    .opacity(mainViewOpacity)
                    .onAppear {
                        if appState.galaxyTargetUserId == nil {
                            appState.galaxyTargetUserId = appState.currentUserId
                        }
                    }
                }
            }
        }
        .animation(.easeInOut(duration: 1.5), value: showSplash)
        .animation(.easeInOut(duration: 1.0), value: appState.navigationState)
        .animation(.easeInOut(duration: 1.2), value: mainViewOpacity)
        .onAppear {
            // 스플래시 화면 표시 후 초기화 (스플래시는 갤럭시 로딩 완료 후에 사라짐)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                initializeAppState()
            }
        }
        .onChange(of: appState.isGalaxyLoadingComplete) { _, isComplete in
            if isComplete && appState.navigationState == .main {
                // 갤럭시 로딩이 완료되면 메인뷰를 먼저 페이드인
                withAnimation(.easeInOut(duration: 1.0)) {
                    mainViewOpacity = 1
                }
                
                // 메인뷰가 나타난 후 스플래시 사라짐 (더 긴 지연)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    withAnimation(.easeInOut(duration: 1.5)) {
                        showSplash = false
                    }
                }
            }
        }
        .onChange(of: appState.navigationState) { _, newState in
            // 네비게이션 상태가 변경될 때마다 메인뷰 투명도 조정
            if newState == .main {
                // 메인뷰로 전환 시
                if appState.isGalaxyLoadingComplete {
                    // 갤럭시 로딩이 완료된 상태라면 바로 표시
                    withAnimation(.easeInOut(duration: 0.8)) {
                        mainViewOpacity = 1
                    }
                } else {
                    // 갤럭시 로딩이 완료되지 않았다면 0으로 유지
                    mainViewOpacity = 0
                }
            } else {
                // 다른 화면으로 전환 시
                withAnimation(.easeInOut(duration: 0.6)) {
                    mainViewOpacity = 1
                }
            }
        }
    }
    
    private func initializeAppState() {
        let hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        let hasAcceptedTerms = UserDefaults.standard.bool(forKey: "hasAcceptedTerms")
        
        appState.hasCompletedOnboarding = hasCompletedOnboarding
        appState.hasAcceptedTerms = hasAcceptedTerms
        
        // Navigation Setting
        if hasCompletedOnboarding {
            if appState.userId != nil {
                appState.navigationState = hasAcceptedTerms ? .main : .terms
            } else {
                appState.navigationState = .login
            }
        } else {
            appState.navigationState = .onboarding
        }
        
        print("iOS App State Initialized - Onboarding: \(hasCompletedOnboarding), Terms: \(hasAcceptedTerms), UserID: \(appState.userId?.uuidString ?? "nil"), NavigationState: \(appState.navigationState)")
    }
}
