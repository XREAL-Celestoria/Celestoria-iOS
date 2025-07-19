//
//  iOSContentView.swift
//  Celestoria
//
//  Created by Assistant on 2025/07/19.
//

import SwiftUI

struct iOSContentView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var loginViewModel: LoginViewModel
    @EnvironmentObject var settingViewModel: SettingViewModel
    
    var body: some View {
        Group {
            switch appState.activeScreen {
            case .login:
                iOSLoginView()
                    .environmentObject(loginViewModel)
                    .transition(.opacity)
                
            case .terms:
                iOSTermsAndConditionsView()
                    .transition(.opacity)
                
            case .main, .galaxy, .explore, .setting:
                iOSMainView()
                    .environmentObject(settingViewModel)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: appState.activeScreen)
    }
}