//
//  AccountSettingView.swift
//  Celestoria
//
//  Created by Park Seyoung on 5/25/25.
//

import SwiftUI

// MARK: - Account Setting View
struct AccountSettingView: View {
    @EnvironmentObject var appModel: AppModel
    @EnvironmentObject var settingViewModel: SettingViewModel
    @State private var showDeleteConfirmation = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isHovered = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Account Setting")
                .font(.system(size: 29, weight: .bold))
                .foregroundColor(.NebulaWhite)
                .padding(.top, 35)
                .padding(.horizontal, 55)
            
            Button(action: {
                showDeleteConfirmation = true
            }) {
                HStack(alignment: .center, spacing: 40) {
                    Text("Delete Account")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(colors: [.white], startPoint: .leading, endPoint: .trailing)
                        )
                }
                .padding(.vertical, 18)
                .padding(.horizontal, 20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    Color.white.opacity(0.1)
                        .opacity(isHovered ? 1 : 0)
                )
                .cornerRadius(20)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 35)
            .padding(.top, 30)
            .onHover { hovering in
                isHovered = hovering
            }
            
            Spacer()
        }
        .alert("Delete Account", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    do {
                        try await settingViewModel.deleteAccount()
                        appModel.activeScreen = .login
                        appModel.userId = nil
                    } catch {
                        errorMessage = error.localizedDescription
                        showError = true
                    }
                }
            }
        } message: {
            Text("Are you sure you want to delete your account? This action cannot be undone.")
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
}

// MARK: - Blocked Users Setting View
struct BlockedUsersSettingView: View {
    @EnvironmentObject var settingViewModel: SettingViewModel
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Blocked Users")
                .font(.system(size: 29, weight: .bold))
                .foregroundColor(.NebulaWhite)
                .padding(.top, 35)
                .padding(.horizontal, 55)
            
            if settingViewModel.isLoadingBlockedUsers {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if settingViewModel.blockedUsers.isEmpty {
                Text("No blocked users")
                    .foregroundColor(.NebulaWhite)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        ForEach(settingViewModel.blockedUsers) { userInfo in
                            BlockedUserRow(
                                userInfo: userInfo,
                                onUnblock: {
                                    Task {
                                        await settingViewModel.unblockUser(userInfo.profile.userId)
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 55)
                    .padding(.top, 20)
                }
            }
        }
        .onAppear {
            Task {
                await settingViewModel.fetchBlockedUsers()
            }
        }
        .alert("오류", isPresented: $showError) {
            Button("확인", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
}

struct BlockedUserRow: View {
    let userInfo: BlockedUserInfo
    let onUnblock: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        HStack {
            // 프로필 이미지
            if let urlString = userInfo.profile.profileImageURL,
               let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(width: 40, height: 40)
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                    case .failure:
                        defaultProfileImage
                    @unknown default:
                        defaultProfileImage
                    }
                }
            } else {
                defaultProfileImage
            }
            
            // 사용자 이름
            Text(userInfo.profile.name)
                .font(.system(size: 22))
                .foregroundColor(.white)
                .padding(.leading, 16)
            
            Spacer()
            
            // 차단 해제 버튼
            Button(action: onUnblock) {
                Text("Unblock")
                    .font(.system(size: 17))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(hex: "#4A4A4A"))
                    )
            }
            .buttonStyle(.plain)
            .opacity(isHovered ? 1 : 0.8)
        }
        .padding(.vertical, 12)
        .onHover { hovering in
            isHovered = hovering
        }
    }
    
    var defaultProfileImage: some View {
        Circle()
            .fill(Color(hex: "#6C6C6C"))
            .frame(width: 40, height: 40)
            .overlay(
                Image(systemName: "person.fill")
                    .foregroundColor(.white)
            )
    }
}
