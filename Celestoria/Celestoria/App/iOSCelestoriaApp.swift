//
//  iOSCelestoriaApp.swift
//  Celestoria
//
//  Created by Park Seyoung on 7/12/25.
//

import SwiftUI

@main
struct iOSCelestoriaApp: App {
    @StateObject private var diContainer = DIContainer()
    
    var body: some Scene {
        WindowGroup {
            iPhoneContentView(diContainer: diContainer)
                .environmentObject(diContainer.appState)
                .environmentObject(diContainer.appState.loginViewModel ?? LoginViewModel(
                    signInUseCase: SignInWithAppleUseCase(repository: diContainer.authRepository),
                    profileUseCase: diContainer.profileUseCase,
                    appState: diContainer.appState
                ))
                .environmentObject(diContainer.settingViewModel)
                .preferredColorScheme(.dark)
        }
    }
}
