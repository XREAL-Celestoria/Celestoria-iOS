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
    
    init(diContainer: DIContainer) {
        self.diContainer = diContainer
    }
    
    var body: some View {
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
                
            case .main:
                iOSMainView(diContainer: diContainer)
                    .environmentObject(settingViewModel)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: appState.navigationState)
        .onAppear {
            // Initialize navigation state based on user status
            if appState.hasCompletedOnboarding {
                if appState.userId != nil {
                    appState.navigationState = appState.hasAcceptedTerms ? .main : .terms
                } else {
                    appState.navigationState = .login
                }
            } else {
                appState.navigationState = .onboarding
            }
        }
    }
}