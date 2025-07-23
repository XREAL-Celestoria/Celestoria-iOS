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
    @Environment(\.dismiss) private var dismiss
    let diContainer: DIContainer
    
    init(diContainer: DIContainer) {
        self.diContainer = diContainer
        _settingViewModel = StateObject(wrappedValue: diContainer.settingViewModel)
    }
    
    var body: some View {
        ZStack {
            // Background
            Color.black
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    // Profile
                    NavigationLink(destination: iOSProfileSettingView(diContainer: diContainer)) {
                        HStack(spacing: 16) {
                            Image(systemName: "person.circle")
                                .font(.system(size: 22))
                                .foregroundColor(.white)
                                .frame(width: 24)
                            
                            Text("Profile")
                                .font(.system(size: 17))
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.5))
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 20)
                    }
                    
                    Divider()
                        .background(Color.white.opacity(0.1))
                        .padding(.leading, 60)
                    
                    // Galaxy
                    NavigationLink(destination: iOSGalaxySettingView(diContainer: diContainer)) {
                        HStack(spacing: 16) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 22))
                                .foregroundColor(.white)
                                .frame(width: 24)
                            
                            Text("Galaxy")
                                .font(.system(size: 17))
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.5))
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 20)
                    }
                    
                    Divider()
                        .background(Color.white.opacity(0.1))
                        .padding(.leading, 60)
                    
                    // Thumbnail
                    NavigationLink(destination: iOSThumbnailSettingView(diContainer: diContainer)) {
                        HStack(spacing: 16) {
                            Image(systemName: "photo")
                                .font(.system(size: 22))
                                .foregroundColor(.white)
                                .frame(width: 24)
                            
                            Text("Thumbnail")
                                .font(.system(size: 17))
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.5))
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 20)
                    }
                    
                    Divider()
                        .background(Color.white.opacity(0.1))
                        .padding(.leading, 60)
                    
                    // Account Setting
                    NavigationLink(destination: iOSAccountSettingView(diContainer: diContainer)) {
                        HStack(spacing: 16) {
                            Image(systemName: "gearshape")
                                .font(.system(size: 22))
                                .foregroundColor(.white)
                                .frame(width: 24)
                            
                            Text("Account Setting")
                                .font(.system(size: 17))
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.5))
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 20)
                    }
                    
                    Divider()
                        .background(Color.white.opacity(0.1))
                        .padding(.leading, 60)
                    
                    // Blocked Users
                    NavigationLink(destination: iOSBlockedUsersSettingView(diContainer: diContainer)) {
                        HStack(spacing: 16) {
                            Image(systemName: "person.2.slash")
                                .font(.system(size: 22))
                                .foregroundColor(.white)
                                .frame(width: 24)
                            
                            Text("Blocked Users")
                                .font(.system(size: 17))
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.5))
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 20)
                    }
                }
                .padding(.top, 20)
            }
        }
        .navigationTitle("Menu")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.primary)
                }
            }
        }
    }
}