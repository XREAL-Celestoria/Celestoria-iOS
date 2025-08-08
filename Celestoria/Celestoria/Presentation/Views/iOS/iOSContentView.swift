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
    @State private var selectedMemory: Memory?
    
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
        .onChange(of: appState.shouldNavigateToMemoryDetail) { shouldNavigate in
            if shouldNavigate, let memory = appState.selectedMemoryForDetail {
                print("🔍 iOSContentView - Memory detail navigation triggered from app state")
                print("🔍 Memory ID: \(memory.id.uuidString)")
                selectedMemory = memory
            }
        }
        .onChange(of: appState.selectedMemoryForDetail) { newMemory in
            // bool 플래그 레이스를 피하기 위해 메모리 자체 변경에도 반응
            if let memory = newMemory {
                print("🔍 iOSContentView - Memory selected via selectedMemoryForDetail change: \(memory.id.uuidString)")
                selectedMemory = memory
            }
        }
        .fullScreenCover(item: $selectedMemory) { memory in
            iOSMemoryDetailView(memory: memory, diContainer: diContainer)
                .onDisappear {
                    // 메모리 디테일 관련 앱 스테이트 리셋
                    appState.selectedMemoryForDetail = nil
                    appState.shouldNavigateToMemoryDetail = false
                }
        }
        .presentationBackground(.clear) // iPad에서 배경 투명하게
        .presentationDragIndicator(.hidden) // 드래그 인디케이터 숨김
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
            ZStack {
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
                
                // 로딩 중일 때만 갤럭시뷰 위에 블러 오버레이 (터치는 통과)
                if !appState.isGalaxyLoadingComplete {
                    iOSUnifiedLoadingView.stars()
                        .allowsHitTesting(false) // 터치 이벤트 통과
                        .onAppear {
                            // 4초 후 자동으로 로딩뷰 숨김 (안전장치)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                                if !appState.isGalaxyLoadingComplete {
                                    print("⏰ Auto-hiding loading view after 4 seconds timeout")
                                    appState.isGalaxyLoadingComplete = true
                                }
                            }
                        }
                }
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
