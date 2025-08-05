//
//  UserInfoModalComponents.swift
//  Celestoria
//
//  Created by Seyoung Park on 8/2/25.
//

import SwiftUI
import os

// MARK: - Close Button Header
struct CloseButtonHeader: View {
    let onClose: () -> Void
    
    var body: some View {
        HStack {
            Button(action: onClose) {
                Image("backButton")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
            }
            .padding(.leading, 16)
            .padding(.top, 8)
            
            Spacer()
        }
    }
}

// MARK: - Profile Header View
struct ProfileHeaderView: View {
    let profile: UserProfile
    @State private var displayName: String = ""
    
    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            ProfileImageView(profile: profile, size: 32)
            
            Text(displayName)
                .fontStyle(Fonts.title3)
                .foregroundColor(Colors.NebulaWhite)
                .lineLimit(1)
                .animation(.easeInOut(duration: 0.3), value: displayName)
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .onAppear {
            displayName = profile.name
        }
        .onChange(of: profile.name) { _, newName in
            withAnimation(.easeInOut(duration: 0.3)) {
                displayName = newName
            }
            Logger.info("ProfileHeaderView: Profile name updated to: \(newName)")
        }
    }
}

// MARK: - Animated Profile Name
struct AnimatedProfileName: View {
    let profileName: String
    @State private var displayName: String = ""
    
    var body: some View {
        Text(displayName)
            .font(.system(size: 18, weight: .semibold))
            .foregroundColor(.white)
            .animation(.easeInOut(duration: 0.3), value: displayName)
            .onAppear {
                displayName = profileName
            }
            .onChange(of: profileName) { _, newName in
                withAnimation(.easeInOut(duration: 0.3)) {
                    displayName = newName
                }
                Logger.info("AnimatedProfileName: Profile name updated to: \(newName)")
            }
    }
}

// MARK: - Profile Image View
struct ProfileImageView: View {
    let profile: UserProfile
    let size: CGFloat
    @State private var imageKey: String = ""
    
    var body: some View {
        Group {
            if let profileKey = profile.profileKey,
               let predefinedImage = PredefinedProfileImage.fromKey(profileKey) {
                Image(predefinedImage.rawValue)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .onAppear {
                        Logger.info("ProfileImageView: Using predefined image - key: \(profileKey), image: \(predefinedImage.rawValue)")
                    }
            } else if let profileImageURL = profile.profileImageURL {
                CachedAsyncImage(urlString: profileImageURL, size: size)
                    .id("\(profileImageURL)_\(imageKey)") // URL과 추가 키로 강제 리로딩
                    .onAppear {
                        Logger.info("ProfileImageView: Using CachedAsyncImage - URL: \(profileImageURL)")
                    }
            } else {
                fallbackImageView
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .onChange(of: profile.profileImageURL) { _, newURL in
            // 프로필 이미지 URL이 변경되면 강제로 새로 로드
            imageKey = UUID().uuidString
            Logger.info("ProfileImageView: Profile image URL changed, forcing reload")
        }
        .onChange(of: profile.profileKey) { _, newKey in
            // 프로필 키가 변경되면 강제로 새로 로드
            imageKey = UUID().uuidString
            Logger.info("ProfileImageView: Profile key changed, forcing reload")
        }
    }
    
    @ViewBuilder
    private var fallbackImageView: some View {
        Image(systemName: "person.circle.fill")
            .font(.system(size: size))
            .foregroundColor(.gray)
            .onAppear {
                Logger.info("ProfileImageView: Using fallback image - profileKey: \(profile.profileKey ?? -1), imageURL: \(profile.profileImageURL ?? "nil")")
            }
    }
}

// MARK: - Stats View
struct StatsView: View {
    let memoryCount: Int
    let commentCount: Int
    let likeCount: Int
    
    var body: some View {
        HStack {
            Spacer()
            HStack(alignment: .center, spacing: 50) {
                StatItem(icon: "Memory-icon", count: memoryCount)
                StatItem(icon: "CommentIcon", count: commentCount)
                StatItem(icon: "Like-on", count: likeCount)
            }
            Spacer()
        }
    }
}

// MARK: - Stat Item
struct StatItem: View {
    let icon: String
    let count: Int
    
    var body: some View {
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
}

// MARK: - Loading View
struct LoadingView: View {
    var body: some View {
        HStack {
            Spacer()
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
            Spacer()
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .frame(height: 100)
    }
}

// MARK: - Add Memory Button
struct AddMemoryButton: View {
    let onAddMemory: () -> Void
    let isExpanded: Bool
    
    var body: some View {
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
        .offset(x: isExpanded ? -24 : -50, y: isExpanded ? 24 : -14)
    }
}

// MARK: - Sort Section View
struct SortSectionView: View {
    @ObservedObject var viewModel: UserInfoModalViewModel
    @State private var showSortOptions = false
    
    var body: some View {
        HStack {
            Text("Sort by")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
            
            Button(action: {
                showSortOptions.toggle()
            }) {
                HStack(spacing: 4) {
                    Text(viewModel.sortOption.displayName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Image(systemName: showSortOptions ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
        )
        .overlay(
            VStack {
                if showSortOptions {
                    VStack(spacing: 8) {
                        ForEach(UserInfoModalViewModel.SortOption.allCases, id: \.self) { option in
                            Button(action: {
                                viewModel.changeSortOption(option)
                                showSortOptions = false
                            }) {
                                HStack {
                                    Text(option.displayName)
                                        .font(.system(size: 16))
                                        .foregroundColor(option == viewModel.sortOption ? .white : .white.opacity(0.7))
                                    Spacer()
                                    if option == viewModel.sortOption {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 14))
                                            .foregroundColor(.white)
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                            }
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.black.opacity(0.8))
                    )
                    .padding(.top, 60)
                }
            }
        )
    }
}

// MARK: - Memory List Item View
struct MemoryListItemView: View {
    let mockMemory: UserInfoModalViewModel.MockMemory
    
    var body: some View {
        HStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.1))
                .frame(width: 80, height: 60)
                .overlay(
                    Image(systemName: "photo")
                        .font(.system(size: 20))
                        .foregroundColor(.white.opacity(0.3))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(mockMemory.title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                
                Text("\(mockMemory.views) views • \(mockMemory.daysAgo) days ago")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Empty Profile View
struct EmptyProfileView: View {
    var body: some View {
        HStack {
            Spacer()
            VStack(spacing: 12) {
                Image(systemName: "person.circle")
                    .font(.system(size: 40))
                    .foregroundColor(.white.opacity(0.3))
                
                Text("Profile not available")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.6))
            }
            Spacer()
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .frame(height: 100)
    }
}
