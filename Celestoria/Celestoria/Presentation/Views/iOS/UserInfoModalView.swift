//
//  UserInfoModalView.swift
//  Celestoria
//
//  Created by Seyoung Park on 8/2/25.
//

import SwiftUI
import Foundation

struct UserInfoModalView: View {
    let userId: UUID
    let isOwnGalaxy: Bool
    let onAddMemory: () -> Void
    let diContainer: DIContainer
    @StateObject private var viewModel: UserInfoModalViewModel
    
    init(userId: UUID, isOwnGalaxy: Bool, onAddMemory: @escaping () -> Void, diContainer: DIContainer) {
        self.userId = userId
        self.isOwnGalaxy = isOwnGalaxy
        self.onAddMemory = onAddMemory
        self.diContainer = diContainer
        _viewModel = StateObject(wrappedValue: diContainer.makeUserInfoModalViewModel(userId: userId))
    }
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            if let profile = viewModel.userProfile {
                profileContentView(profile: profile)
                    .modifier(ModalStyleModifier())
                    .padding(.horizontal, 28)
                
                // Add memory button
                addMemoryButton
                
            } else {
                loadingView
                    .modifier(ModalStyleModifier())
                    .padding(.horizontal, 20)
            }
        }
    }
    
    // MARK: - Profile Content View
    private func profileContentView(profile: UserProfile) -> some View {
        VStack {
            Spacer()
                .frame(height: 14)
            
            profileHeaderView(profile: profile)
            
            Spacer()
                .frame(height: 16)
            
            statsView
            
            Spacer()
                .frame(height: 20)
        }
        .frame(maxWidth: .infinity, maxHeight: 112)
    }
    
    // MARK: - Profile Header View
    private func profileHeaderView(profile: UserProfile) -> some View {
        HStack(alignment: .center, spacing: 8) {
            profileImageView(profile: profile)
            
            Text(profile.name)
                .fontStyle(Fonts.title3)
                .foregroundColor(Colors.NebulaWhite)
                .lineLimit(1)
            
            Spacer()
        }
        .padding(.horizontal, 16)
    }
    
    // MARK: - Profile Image View
    private func profileImageView(profile: UserProfile) -> some View {
        Group {
            if let profileKey = profile.profileKey,
               let predefinedImage = PredefinedProfileImage.fromKey(profileKey) {
                Image(predefinedImage.rawValue)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else if let profileImageURL = profile.profileImageURL {
                AsyncImage(url: URL(string: profileImageURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.gray)
                }
            } else {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.gray)
            }
        }
        .frame(width: 32, height: 32)
        .clipShape(Circle())
    }
    
    // MARK: - Stats View
    private var statsView: some View {
        HStack {
            Spacer()
            HStack(alignment: .center, spacing: 50) {
                statItem(icon: "Memory-icon", count: viewModel.memoryCount)
                statItem(icon: "CommentIcon", count: viewModel.commentCount)
                statItem(icon: "Like-on", count: viewModel.likeCount)
            }
            Spacer()
        }
    }
    
    // MARK: - Stat Item
    private func statItem(icon: String, count: Int) -> some View {
        HStack(alignment: .center, spacing: 8) {
            Image(icon)
                .resizable()
                .scaledToFit()
                .frame(width: 18, height: 18)
            
            Text("\(count)")
                .fontStyle(Fonts.callout)
                .foregroundColor(Colors.NebulaWhite)
        }
        .frame(minWidth: 60)
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        HStack {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
            Spacer()
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .frame(height: 100)
    }
    
    private var addMemoryButton: some View {
        Group {
            if isOwnGalaxy {
                Button(action: onAddMemory) {
                    HStack(alignment: .center, spacing: 4) {
                        Image("addMemoryIcon")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                        
                        Text("Add")
                            .fontStyle(Fonts.caption1)
                            .foregroundColor(Colors.NebulaWhite)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.275, green: 0.325, blue: 0.439), // #465370
                                Color(red: 0.290, green: 0.463, blue: 0.624) // #4A769F
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .cornerRadius(40)
                    .shadow(color: Color(red: 0.42, green: 0.73, blue: 1).opacity(0.4), radius: 2, x: 0, y: 0)
                    .shadow(color: Color(red: 0.5, green: 0.8, blue: 1).opacity(0.3), radius: 4, x: 0, y: 0)
                    .shadow(color: Color(red: 0.6, green: 0.85, blue: 1).opacity(0.2), radius: 6, x: 0, y: 0)
                    .overlay(
                        RoundedRectangle(cornerRadius: 40)
                            .inset(by: 0.75)
                            .stroke(Color(red: 0.65, green: 0.91, blue: 1), lineWidth: 1.5)
                    )
                }
                .offset(x: -50, y: -14)
            } else {
                EmptyView()
            }
        }
    }
}

// MARK: - Modal Style Modifier
struct ModalStyleModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.141, green: 0.263, blue: 0.388), // #244363
                        Color(red: 0.094, green: 0.098, blue: 0.145) // #181925
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.4, green: 0.6, blue: 0.9).opacity(0.2),
                                Color(red: 0.3, green: 0.5, blue: 0.8).opacity(0.1)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .cornerRadius(24)
            .shadow(color: Color(red: 0.4, green: 0.7, blue: 1).opacity(0.6), radius: 6, x: 0, y: 0)
            .shadow(color: Color(red: 0.4, green: 0.7, blue: 1).opacity(0.4), radius: 8, x: 0, y: 0)
    }
}
