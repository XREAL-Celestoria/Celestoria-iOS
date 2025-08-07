//
//  iOSAccountSettingView.swift
//  Celestoria
//
//  Created by Minjun Kim on 7/20/25.
//


import SwiftUI

struct iOSAccountSettingView: View {
    @StateObject private var settingViewModel: SettingViewModel
    @EnvironmentObject var appState: AppState
    @State private var showDeleteConfirmation = false
    @State private var errorMessage: String?
    @Environment(\.dismiss) private var dismiss
    let diContainer: DIContainer
    
    init(diContainer: DIContainer) {
        self.diContainer = diContainer
        _settingViewModel = StateObject(wrappedValue: diContainer.settingViewModel)
    }
    
    var body: some View {
        ZStack {
            // Background
            Colors.BackgroundBlack
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                
                deleteAccountButton
                
                signoutButton
                
                Spacer()
            }
            .padding(.top, 20)
            
            if showDeleteConfirmation {
                iOSConfirmationPopupView(title: "Delete Your Account", message: "Are you sure you want to continue? This action cannot be undone.", cancelTitle: "Cancel", confirmTitle: "Delete", isDestructive: true, onCancel: {dismiss()}, onConfirm: {
                    Task {
                        do {
                            try await settingViewModel.deleteAccount()
                        } catch {
                            errorMessage = error.localizedDescription
                        }
                    }
                })
            }
        }
        .navigationTitle("Account Setting")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    Image("backButton")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                }
            }
        }
    }
    
    // MARK: - View Components
    private var deleteAccountButton: some View {
        Button(action: {
            showDeleteConfirmation = true
        }) {
            HStack {
                Spacer()
                    .frame(width: 20)
                
                Text("Delete Account")
                    .fontStyle(Fonts.body1)
                    .foregroundStyle(Colors.NebulaWhite)
                
                Spacer()
            }
            .padding(.vertical, 12)
        }
    }
    
    private var signoutButton: some View {
        Button(action: {
            Task {
                do {
                    try await settingViewModel.signOut()
                } catch {
                    errorMessage = error.localizedDescription
                }
            }
        }) {
            HStack {
                Spacer()
                    .frame(width: 20)
                
                Text("Sign out")
                    .fontStyle(Fonts.body1)
                    .foregroundStyle(Colors.NebulaWhite)
                
                Spacer()
            }
            .padding(.vertical, 12)
        }
    }
}
