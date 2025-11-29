//
//  ContentView.swift
//  Celestoria
//
//  Created by Minjun Kim on 1/16/25.
//

import SwiftUI
import RealityKit
import RealityKitContent
import os

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var mainViewModel: MainViewModel
    @EnvironmentObject var loginViewModel: LoginViewModel
    @EnvironmentObject var diContainer: DIContainer
    @State private var activeScreen: ActiveScreen = .login
    
    var body: some View {
        Group {
            switch appState.activeScreen {
            case .login:
                GradientBorderContainer {
                    LoginView()
                        .environmentObject(loginViewModel)
                        .transition(.opacity)
                        .onAppear {
                            Logger.info("Displaying Login View")
                        }
                }
            case .terms:
                GradientBorderContainer {
                    TermsAndConditionsView()
                        .transition(.opacity)
                        .onAppear {
                            Logger.info("Displaying Terms and Conditions View")
                        }
                }
            case .main:
                GradientBorderContainer {
                    MainView()
                        .environmentObject(mainViewModel)
                        .transition(.opacity)
                        .onAppear {
                            Logger.info("Displaying Main View")
                            appState.showAddMemoryView = false
                        }
                }
            case .galaxy:
                GradientBorderContainer {
                    GalaxyView()
                        .transition(.opacity)
                        .onAppear {
                            Logger.info("Displaying Galaxy View")
                        }
                }
            case .explore:
                GradientBorderContainer {
                    ExploreView()
                        .transition(.opacity)
                        .onAppear {
                            Logger.info("Displaying Explore View")
                        }
                }
            case .setting:
                GradientBorderContainer {
                    SettingView()
                        .transition(.opacity)
                        .onAppear {
                            Logger.info("Setting Login View")
                        }
                }
            }
        }
        .onAppear {
            Task {
                await checkAuthenticationStatus()
            }
        }
        .onChange(of: appState.userId) { oldValue, newUserId in
            // userId가 nil이 되면 로그인 화면으로 이동
            if newUserId == nil && appState.activeScreen != .login {
                Logger.info("User ID is nil, redirecting to login")
                appState.activeScreen = .login
            }
        }
        .task {
            // 주기적으로 인증 상태 체크 (30초마다)
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 30_000_000_000) // 30초
                await checkAuthenticationStatus()
            }
        }
    }
    
    @MainActor
    private func checkAuthenticationStatus() async {
        // Supabase 인증 상태 확인
        let currentUser = diContainer.supabaseClient.auth.currentUser
        
        // userId가 nil이거나 Supabase 인증이 없으면 로그인 화면으로
        if appState.userId == nil || currentUser == nil {
            if appState.activeScreen != .login {
                Logger.info("No authentication found, redirecting to login")
                appState.userId = nil
                appState.userProfile = nil
                appState.activeScreen = .login
            }
        } else if let userId = appState.userId, let authUserId = currentUser?.id, userId != authUserId {
            // userId와 Supabase 인증 사용자 ID가 다르면 로그인 화면으로
            Logger.warning("User ID mismatch, redirecting to login")
            appState.userId = nil
            appState.userProfile = nil
            appState.activeScreen = .login
        }
    }
}

