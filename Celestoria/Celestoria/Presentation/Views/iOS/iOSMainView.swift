//
//  iOSMainView.swift
//  Celestoria
//
//  Created by Assistant on 2025/07/19.
//

import SwiftUI

struct iOSMainView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var settingViewModel: SettingViewModel
    
    var body: some View {
        ZStack {
            // Background
            Color.NebulaBlack
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Navigation Bar
                HStack {
                    Text("Celestoria")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(LinearGradient.GradientMain)
                    
                    Spacer()
                    
                    Button(action: {
                        Task {
                            do {
                                try await settingViewModel.signOut()
                                appState.activeScreen = .login
                            } catch {
                                print("Sign out error: \(error)")
                            }
                        }
                    }) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.NebulaWhite)
                            .frame(width: 32, height: 32)
                            .background(Color(hex: "E7E7E7").opacity(0.2))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                
                // Content
                ScrollView {
                    VStack(spacing: 24) {
                        // Profile Section
                        if let userProfile = appState.userProfile {
                            VStack(spacing: 16) {
                                // Profile Image
                                if let profileImageUrl = userProfile.profileImage {
                                    AsyncImage(url: URL(string: profileImageUrl)) { image in
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 100, height: 100)
                                            .clipShape(Circle())
                                    } placeholder: {
                                        Circle()
                                            .fill(LinearGradient.GradientMain)
                                            .frame(width: 100, height: 100)
                                            .overlay(
                                                Text(userProfile.username.prefix(1).uppercased())
                                                    .font(.system(size: 40, weight: .bold))
                                                    .foregroundColor(.NebulaBlack)
                                            )
                                    }
                                } else {
                                    Circle()
                                        .fill(LinearGradient.GradientMain)
                                        .frame(width: 100, height: 100)
                                        .overlay(
                                            Text(userProfile.username.prefix(1).uppercased())
                                                .font(.system(size: 40, weight: .bold))
                                                .foregroundColor(.NebulaBlack)
                                        )
                                }
                                
                                // Username
                                Text(userProfile.username)
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(.NebulaWhite)
                                
                                // Bio
                                if let bio = userProfile.bio {
                                    Text(bio)
                                        .font(.system(size: 16))
                                        .foregroundColor(.NebulaWhite.opacity(0.8))
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 40)
                                }
                            }
                            .padding(.top, 20)
                        }
                        
                        // Placeholder content
                        VStack(spacing: 20) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 60))
                                .foregroundStyle(LinearGradient.GradientMain)
                                .padding(.top, 40)
                            
                            Text("Welcome to Celestoria")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(.NebulaWhite)
                            
                            Text("Your spatial video memories will appear here")
                                .font(.system(size: 16))
                                .foregroundColor(.NebulaWhite.opacity(0.6))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                            
                            // Coming Soon Badge
                            HStack {
                                Image(systemName: "clock.fill")
                                    .font(.system(size: 14))
                                Text("Full iOS experience coming soon")
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .foregroundColor(.NebulaWhite.opacity(0.8))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.Profile.opacity(0.3))
                            .cornerRadius(20)
                            .padding(.top, 20)
                        }
                        .padding(.vertical, 40)
                    }
                }
            }
        }
    }
}