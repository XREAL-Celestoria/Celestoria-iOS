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
    @State private var showDeleteAlert = false
    @State private var deleteError: String?
    @Environment(\.dismiss) private var dismiss
    let diContainer: DIContainer
    
    init(diContainer: DIContainer) {
        self.diContainer = diContainer
        _settingViewModel = StateObject(wrappedValue: diContainer.settingViewModel)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Account Info Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Account Information")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("User ID")
                                .font(.system(size: 16))
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(appState.userId?.uuidString ?? "Unknown")
                                .font(.system(size: 16))
                                .foregroundColor(.primary)
                        }
                        
                        Divider()
                        
                        HStack {
                            Text("Account Type")
                                .font(.system(size: 16))
                                .foregroundColor(.secondary)
                            Spacer()
                            HStack(spacing: 4) {
                                Image(systemName: "apple.logo")
                                    .font(.system(size: 14))
                                Text("Sign in with Apple")
                                    .font(.system(size: 16))
                            }
                            .foregroundColor(.primary)
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                }
                
                // Danger Zone
                VStack(alignment: .leading, spacing: 16) {
                    Text("Danger Zone")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.red)
                    
                    Text("Once you delete your account, there is no going back. Please be certain.")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    
                    Button(action: {
                        showDeleteConfirmation = true
                    }) {
                        HStack {
                            Image(systemName: "trash.fill")
                                .font(.system(size: 18))
                            Text("Delete Account")
                                .font(.system(size: 17, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.red)
                        .cornerRadius(12)
                    }
                }
                .padding(.top, 30)
            }
            .padding()
        }
        .navigationTitle("Account")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(
            "Delete Account",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Account", role: .destructive) {
                showDeleteAlert = true
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete your account? This action cannot be undone.")
        }
        .alert(
            "Final Confirmation",
            isPresented: $showDeleteAlert
        ) {
            Button("Cancel", role: .cancel) {}
            Button("Delete Forever", role: .destructive) {
                Task {
                    do {
                        try await settingViewModel.deleteAccount()
                        // Reset app state
                        appState.activeScreen = .login
                        appState.userId = nil
                        appState.userProfile = nil
                        dismiss()
                    } catch {
                        deleteError = error.localizedDescription
                    }
                }
            }
        } message: {
            Text("This will permanently delete your account and all associated data. This action is irreversible.")
        }
        .alert(
            "Error",
            isPresented: .constant(deleteError != nil),
            presenting: deleteError
        ) { _ in
            Button("OK") {
                deleteError = nil
            }
        } message: { error in
            Text(error)
        }
    }
}