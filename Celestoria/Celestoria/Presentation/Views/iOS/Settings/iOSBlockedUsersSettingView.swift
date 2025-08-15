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
            Colors.BackgroundBlack
                .ignoresSafeArea()
            
            if settingViewModel.isLoadingBlockedUsers {
                iOSUnifiedLoadingView.basic(title: "Loading Blocked Users.")
            } else if settingViewModel.blockedUsers.isEmpty {
                VStack(alignment: .center) {
                    Spacer()
                    
                    Image("blockedIcon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                    
                    Spacer()
                        .frame(height: 44)
                    
                    Text("You haven't blocked anyone")
                        .fontStyle(Fonts.title2)
                        .foregroundStyle(Colors.NebulaWhite)
                    
                    Spacer()
                        .frame(height: 24)
                    
                    Text("Once you block someone, you and that person will no longer be able to see each other's uploads.")
                        .fontStyle(Fonts.body1)
                        .foregroundStyle(Colors.NebulaWhite)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 56)
                    
                    Spacer()
                }
                .padding()
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(settingViewModel.blockedUsers) { blockedUser in
                            HStack(spacing: 16) {
                                // Profile Image - ProfileImageView 사용
                                ProfileImageView(
                                    profile: blockedUser.profile,
                                    size: 32
                                )
                                
                                // User Name - 중앙 정렬
                                Text(blockedUser.profile.name)
                                    .fontStyle(Fonts.title3)
                                    .foregroundColor(Colors.NebulaWhite)
                                    .lineLimit(1)
                                
                                Spacer()
                                
                                // Unblock Button - 둥근 모서리, 이미지와 같은 스타일
                                Button(action: {
                                    Task {
                                        await settingViewModel.unblockUser(blockedUser.block.blockedUserId)
                                    }
                                }) {
                                    Text("Unblock")
                                        .fontStyle(Fonts.caption1)
                                        .foregroundColor(Colors.NebulaWhite)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(Color.gray.opacity(0.3))
                                        .cornerRadius(10)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            .background(Color.clear)
                        }
                    }
                    .background(Colors.BackgroundBlack)
                }
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
