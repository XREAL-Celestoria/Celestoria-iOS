//
//  iOSSettingsView.swift
//  Celestoria
//
//  Created by Minjun Kim on 7/20/25.
//


import SwiftUI

struct iOSSettingsView: View {
    @StateObject private var settingViewModel: SettingViewModel
    @EnvironmentObject var appState: AppState
    @Binding var navigationPath: [iOS3DGalaxyContainerView.SettingsScreen]
    let diContainer: DIContainer
    let onBack: () -> Void
    
    init(diContainer: DIContainer, navigationPath: Binding<[iOS3DGalaxyContainerView.SettingsScreen]>, onBack: @escaping () -> Void) {
        self.diContainer = diContainer
        self._navigationPath = navigationPath
        self.onBack = onBack
        _settingViewModel = StateObject(wrappedValue: diContainer.settingViewModel)
    }
    
    var body: some View {
        ZStack {
            // Background
            Colors.BackgroundBlack
                .ignoresSafeArea()
            
            if settingViewModel.isLoading {
                iOSUnifiedLoadingView.basic(title: "Loading Settings.")
            } else {
                ScrollView {
                    VStack(spacing: 24) {
                        // Galaxy
                        Button(action: {
                            navigationPath.append(.galaxy)
                        }) {
                            HStack(spacing: 16) {
                                Image("galaxyMenuIcon")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 24, height: 24)
                                
                                Text("Galaxy")
                                    .fontStyle(Fonts.body1)
                                    .foregroundColor(Colors.NebulaWhite)
                                
                                Spacer()
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 8)
                        }
                        
                        // Profile
                        Button(action: {
                            navigationPath.append(.profile)
                        }) {
                            HStack(spacing: 16) {
                                Image("profileMenuIcon")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 24, height: 24)
                                
                                Text("Profile")
                                    .fontStyle(Fonts.body1)
                                    .foregroundColor(Colors.NebulaWhite)
                                
                                Spacer()
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 8)
                        }
                
                        // Thumbnail
                        Button(action: {
                            navigationPath.append(.thumbnail)
                        }) {
                            HStack(spacing: 16) {
                                Image("thumbnailMenuIcon")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 24, height: 24)
                                
                                Text("Thumbnail")
                                    .fontStyle(Fonts.body1)
                                    .foregroundColor(Colors.NebulaWhite)
                                
                                Spacer()
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 8)
                        }
                        
                        // Account Setting
                        Button(action: {
                            navigationPath.append(.account)
                        }) {
                            HStack(spacing: 16) {
                                Image("accountSettingMenuIcon")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 24, height: 24)
                                
                                Text("Account Setting")
                                    .fontStyle(Fonts.body1)
                                    .foregroundColor(Colors.NebulaWhite)
                                
                                Spacer()
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 8)
                        }
                        
                        // Blocked Users
                        Button(action: {
                            navigationPath.append(.blockedUsers)
                        }) {
                            HStack(spacing: 16) {
                                Image("blockUserMenuIcon")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 24, height: 24)
                                
                                Text("Blocked Users")
                                    .fontStyle(Fonts.body1)
                                    .foregroundColor(Colors.NebulaWhite)
                                
                                Spacer()
                            }
                            .padding(.horizontal, 24)
                            .padding(.vertical, 8)
                        }
                    }
                    .padding(.top, 20)
                }
            }
        }
        .customNavigationBar(title: "Menu", onBack: onBack)
    }
}
