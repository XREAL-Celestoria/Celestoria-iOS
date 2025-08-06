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
            
            if settingViewModel.blockedUsers.isEmpty {
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
                                    Image(PredefinedProfileImage.profile_blue.rawValue)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                }
                            }
                            .frame(width: 32, height: 32)
                            .clipShape(Circle())
                            
                            // User Info
                            Text(blockedUser.profile.name)
                                .fontStyle(Fonts.title3)
                                .foregroundColor(Colors.NebulaWhite)
                            
                            Spacer()
                            
                            // Unblock Button
                            Button(action: {
                                Task {
                                    await settingViewModel.unblockUser(blockedUser.block.blockedUserId)
                                }
                            }) {
                                Text("Unblock")
                                    .fontStyle(Fonts.caption1)
                                    .foregroundColor(Colors.NebulaWhite)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 10)
                                    .background(Colors.AccountSelectedBtn)
                                    .cornerRadius(10)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
                .listStyle(PlainListStyle())
                .scrollContentBackground(.hidden)
                .background(Colors.BackgroundBlack)
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
