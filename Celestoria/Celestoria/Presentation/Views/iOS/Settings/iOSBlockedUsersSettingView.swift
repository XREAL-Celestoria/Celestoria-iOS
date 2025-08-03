//
//  iOSBlockedUsersSettingView.swift
//  Celestoria
//
//  Created by Minjun Kim on 7/20/25.
//


import SwiftUI

struct iOSBlockedUsersSettingView: View {
    @StateObject private var settingViewModel: SettingViewModel
    @Environment(\.dismiss) private var dismiss
    let diContainer: DIContainer
    
    init(diContainer: DIContainer) {
        self.diContainer = diContainer
        _settingViewModel = StateObject(wrappedValue: diContainer.settingViewModel)
    }
    
    var body: some View {
        ZStack {
            if settingViewModel.blockedUsers.isEmpty {
                VStack(spacing: 20) {
                    Spacer()
                    
                    Image(systemName: "hand.raised.slash.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    
                    Text("No Blocked Users")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text("Users you block will appear here")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Spacer()
                }
                .padding()
            } else {
                List {
                    ForEach(settingViewModel.blockedUsers) { blockedUser in
                        HStack {
                            // Profile Image
                            Group {
                                if let profileKey = blockedUser.profile.profileKey,
                                   let predefinedImage = PredefinedProfileImage.fromKey(profileKey) {
                                    Image(predefinedImage.rawValue)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } else if let profileImageUrl = blockedUser.profile.profileImageURL {
                                    AsyncImage(url: URL(string: profileImageUrl)) { image in
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                    } placeholder: {
                                        Circle()
                                            .fill(Color.gray.opacity(0.3))
                                    }
                                } else {
                                    Circle()
                                        .fill(LinearGradient.GradientMain)
                                        .overlay(
                                            Text(blockedUser.profile.name.prefix(1).uppercased())
                                                .font(.system(size: 20, weight: .bold))
                                                .foregroundColor(Colors.NebulaBlack)
                                        )
                                }
                            }
                            .frame(width: 50, height: 50)
                            .clipShape(Circle())
                            
                            // User Info
                            VStack(alignment: .leading, spacing: 4) {
                                Text(blockedUser.profile.name)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.primary)
                                
                                Text("Blocked")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            // Unblock Button
                            Button(action: {
                                Task {
                                    await settingViewModel.unblockUser(blockedUser.block.blockedUserId)
                                }
                            }) {
                                Text("Unblock")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(Color.red)
                                    .cornerRadius(8)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
                .listStyle(PlainListStyle())
            }
        }
        .navigationTitle("Blocked Users")
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
        .task {
            await settingViewModel.fetchBlockedUsers()
        }
        .refreshable {
            await settingViewModel.fetchBlockedUsers()
        }
    }
}
