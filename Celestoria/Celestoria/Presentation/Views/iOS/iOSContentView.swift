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
                    .id("splash-\(appState.navigationState)")  // 상태 변경 시 새로 생성
                    .transition(.opacity)
                    .zIndex(2)
            }
            
            // 메인 컨텐츠 (스플래시가 true일 때는 투명하게 로드)
            Group {
                switch appState.navigationState {
                case .onboarding:
                    iOSOnboardingView()
                        .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                        .opacity(mainViewOpacity)
                    
                case .login:
                    iOSLoginView()
                        .environmentObject(loginViewModel)
                        .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                        .opacity(mainViewOpacity)
                    
                case .terms:
                    iOSTermsAndConditionsView()
                        .opacity(mainViewOpacity)
                        .zIndex(1)
                    
                case .main:
                    NavigationView {
                        iOS3DGalaxyContainerView(diContainer: diContainer)
                            .navigationBarHidden(true)
                    }
                    .navigationViewStyle(StackNavigationViewStyle())
                    .environmentObject(settingViewModel)
                    .transition(.opacity)
                    .zIndex(0)
                    .opacity(mainViewOpacity)
                    .onAppear {
                        if appState.galaxyTargetUserId == nil {
                            appState.galaxyTargetUserId = appState.currentUserId
                        }
                        
                        // 갤럭시 로딩 완료 상태 체크 (안전장치)
                        if appState.isGalaxyLoadingComplete && showSplash {
                            print("🔧 iOSContentView: Galaxy already loaded, hiding splash immediately")
                            withAnimation(.easeInOut(duration: 0.8)) {
                                showSplash = false
                                mainViewOpacity = 1
                            }
                        }
                    }
                }
            }
        }
        .animation(.easeInOut(duration: 0.8), value: showSplash)
        .animation(.easeInOut(duration: 0.6), value: appState.navigationState)
        .animation(.easeInOut(duration: 0.8), value: mainViewOpacity)
        .onAppear {
            // 로그인된 사용자가 없으면 바로 스플래시 숨기고 초기화
            if appState.userId == nil {
                showSplash = false
                mainViewOpacity = 1
            }
            
            // 스플래시 화면 표시 후 초기화 (스플래시는 갤럭시 로딩 완료 후에 사라짐)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                initializeAppState()
            }
        }
        .onChange(of: appState.isGalaxyLoadingComplete) { _, isComplete in
            print("🔧 iOSContentView: Galaxy loading complete changed to \(isComplete), navigationState: \(appState.navigationState), showSplash: \(showSplash)")
            if isComplete && appState.navigationState == .main && showSplash {
                print("🔧 iOSContentView: Hiding splash screen due to galaxy loading complete")
                // 갤럭시 로딩이 완료되면 자연스럽게 크로스페이드
                withAnimation(.easeInOut(duration: 0.8)) {
                    showSplash = false
                    mainViewOpacity = 1
                }
            } else if isComplete && appState.navigationState == .main && !showSplash {
                print("🔧 iOSContentView: Galaxy loading complete but splash already hidden - ensuring main view is visible")
                // 스플래시가 이미 숨겨진 상태라면 메인 뷰만 보이도록
                withAnimation(.easeInOut(duration: 0.4)) {
                    mainViewOpacity = 1
                }
            }
        }
        .onChange(of: appState.navigationState) { oldState, newState in
            print("🔧 iOSContentView: Navigation state changed from \(oldState) to \(newState), current showSplash: \(showSplash), galaxyLoading: \(appState.isGalaxyLoadingComplete)")
            
            if oldState == .terms && newState == .main {
                // 약관에서 메인으로: 갤럭시 로딩 상태 확인
                if appState.isGalaxyLoadingComplete {
                    print("🔧 iOSContentView: Galaxy already loaded, going directly to main")
                    // 이미 로딩 완료되었다면 바로 메인 화면 표시
                    withAnimation(.easeInOut(duration: 0.5)) {
                        showSplash = false
                        mainViewOpacity = 1
                    }
                } else {
                    print("🔧 iOSContentView: Galaxy not loaded, showing splash first")
                    // 로딩이 안 되었다면 스플래시 표시 (딜레이 제거)
                    withAnimation(.easeInOut(duration: 0.4)) {
                        showSplash = true
                        mainViewOpacity = 0
                    }
                }
            } else if oldState == .login && newState == .main {
                // 로그인에서 메인으로: 스플래시 상태 완전 초기화
                print("🔧 iOSContentView: Login to main - initializing splash state")
                showSplash = true
                mainViewOpacity = 0
                // 갤럭시 로딩 완료 후 자동으로 사라지도록
            } else if newState == .main {
                // 다른 화면에서 메인으로
                print("🔧 iOSContentView: Other screen to main")
                withAnimation(.easeInOut(duration: 0.4)) {
                    showSplash = true
                    mainViewOpacity = 0
                }
            } else {
                // 다른 화면으로 전환 시 (온보딩, 로그인, 약관 동의)
                print("🔧 iOSContentView: Going to non-main screen")
                withAnimation(.easeInOut(duration: 0.4)) {
                    showSplash = false
                    mainViewOpacity = 1
                }
            }
        }
    }
    
    private func initializeAppState() {
        // DIContainer에서 이미 로그인된 사용자가 있다면 초기화를 건너뜀
        if appState.userId != nil {
            print("iOS App State: User already logged in, skipping initialization - UserID: \(appState.userId?.uuidString ?? "nil"), NavigationState: \(appState.navigationState)")
            return
        }
        
        // 로그인되지 않은 경우에만 UserDefaults를 확인하여 초기화
        let hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        let hasAcceptedTerms = UserDefaults.standard.bool(forKey: "hasAcceptedTerms")
        
        appState.hasCompletedOnboarding = hasCompletedOnboarding
        appState.hasAcceptedTerms = hasAcceptedTerms
        
        // Navigation Setting
        if hasCompletedOnboarding {
            appState.navigationState = .login
        } else {
            appState.navigationState = .onboarding
        }
        
        print("iOS App State Initialized - Onboarding: \(hasCompletedOnboarding), Terms: \(hasAcceptedTerms), UserID: nil, NavigationState: \(appState.navigationState)")
    }
}
