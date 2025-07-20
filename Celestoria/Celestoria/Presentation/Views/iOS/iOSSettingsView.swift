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
        List {
            // Profile Section
            Section {
                NavigationLink(destination: iOSProfileSettingView(diContainer: diContainer)) {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(LinearGradient.GradientMain)
                        Text("Profile")
                            .font(.system(size: 17))
                    }
                }
                
                NavigationLink(destination: iOSThumbnailSettingView(diContainer: diContainer)) {
                    HStack {
                        Image(systemName: "photo.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(LinearGradient.GradientMain)
                        Text("Space Thumbnail")
                            .font(.system(size: 17))
                    }
                }
            }
            
            // Privacy Section
            Section {
                NavigationLink(destination: iOSBlockedUsersSettingView(diContainer: diContainer)) {
                    HStack {
                        Image(systemName: "hand.raised.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(LinearGradient.GradientMain)
                        Text("Blocked Users")
                            .font(.system(size: 17))
                    }
                }
            }
            
            // Account Section
            Section {
                NavigationLink(destination: iOSAccountSettingView(diContainer: diContainer)) {
                    HStack {
                        Image(systemName: "person.badge.shield.checkmark.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(LinearGradient.GradientMain)
                        Text("Account")
                            .font(.system(size: 17))
                    }
                }
            }
            
            // Sign Out Section
            Section {
                Button(action: {
                    Task {
                        do {
                            try await settingViewModel.signOut()
                            appState.hasCompletedOnboarding = false
                            appState.hasAcceptedTerms = false
                            appState.navigationState = .onboarding
                            dismiss()
                        } catch {
                            print("Sign out error: \(error)")
                        }
                    }
                }) {
                    HStack {
                        Spacer()
                        Text("Sign Out")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(.red)
                        Spacer()
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
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