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
        Group {
            if showSplash {
                iOSSplashView()
                    .transition(.opacity)
            } else {
                Group {
                    switch appState.navigationState {
                    case .onboarding:
                        iOSOnboardingView()
                            .transition(.opacity)
                        
                    case .login:
                        iOSLoginView()
                            .environmentObject(loginViewModel)
                            .transition(.opacity)
                        
                    case .terms:
                        iOSTermsAndConditionsView()
                            .transition(.opacity)
                            .zIndex(1)
                        
                    case .main:
                        iOSMainView(diContainer: diContainer)
                            .environmentObject(settingViewModel)
                            .transition(.opacity)
                            .zIndex(0)
                    }
                }
            }
        }
        .animation(.easeInOut(duration: 0.8), value: showSplash)
        .animation(.easeInOut(duration: 0.6), value: appState.navigationState)
        .onAppear {
            // 스플래시 화면 표시 후 초기화
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                initializeAppState()
                withAnimation(.easeInOut(duration: 0.8)) {
                    showSplash = false
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
