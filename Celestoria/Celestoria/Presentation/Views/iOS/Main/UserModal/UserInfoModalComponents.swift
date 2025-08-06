//
//  UserInfoModalComponents.swift
//  Celestoria
//
//  Created by Seyoung Park on 8/2/25.
//

import SwiftUI
import os

// MARK: - Profile Tab Enum
enum ProfileTab: String, CaseIterable {
    case memories = "memories"
    case comments = "comments"
    case likes = "likes"
    
    var displayName: String {
        switch self {
        case .memories:
            return "Memories"
        case .comments:
            return "Comments"
        case .likes:
            return "Likes"
        }
    }
}

// MARK: - Thumbnail Section View
struct ThumbnailSectionView: View {
    let profile: UserProfile
    
    // Helper function to map thumbnail IDs to asset names
    private func thumbnailName(for id: String) -> String {
        if let intId = Int(id), intId >= 1 && intId <= 6 {
            return "Thumbnail\(intId)"
        } else {
            return "Thumbnail1"
        }
    }
    
    var body: some View {
        Group{
            if let thumbnailId = profile.spaceThumbnailId {
                // 썸네일 배경
                Image(thumbnailName(for: thumbnailId))
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: UIScreen.main.bounds.width, height: 240)
                    .cornerRadius(28, corners: .topLeft)
                    .cornerRadius(28, corners: .topRight)
                    .clipped()
                
            }
        }
        .transition(.scale.combined(with: .opacity))
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

// MARK: - Profile Header Stats View (Combined)
struct ProfileHeaderStatsView: View {
    let profile: UserProfile
    let memoryCount: Int
    let commentCount: Int
    let likeCount: Int
    let showEditButton: Bool
    let isExpanded: Bool
    let selectedTab: ProfileTab
    let onEditTap: () -> Void
    let onTabSelected: (ProfileTab) -> Void
    @State private var displayName: String = ""
    
    init(profile: UserProfile, memoryCount: Int, commentCount: Int, likeCount: Int, showEditButton: Bool = false, isExpanded: Bool = false, selectedTab: ProfileTab = .memories, onEditTap: @escaping () -> Void = {}, onTabSelected: @escaping (ProfileTab) -> Void = { _ in }) {
        self.profile = profile
        self.memoryCount = memoryCount
        self.commentCount = commentCount
        self.likeCount = likeCount
        self.showEditButton = showEditButton
        self.isExpanded = isExpanded
        self.selectedTab = selectedTab
        self.onEditTap = onEditTap
        self.onTabSelected = onTabSelected
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Profile Header
            HStack(alignment: .center, spacing: 8) {
                ProfileImageView(profile: profile, size: 32)
                
                Text(displayName)
                    .fontStyle(Fonts.title3)
                    .foregroundColor(Colors.NebulaWhite)
                    .lineLimit(1)
                    .animation(.easeInOut(duration: 0.3), value: displayName)
                
                Spacer()
                
                if showEditButton {
                    Button(action: onEditTap) {
                        Image("profileEditIcon")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 16, height: 16)
                    }
                }
            }
            .padding(.horizontal, 20)
            
            // Stats / Tab Buttons
            HStack {
                Spacer()
                HStack(alignment: .center, spacing: 50) {
                    if isExpanded {
                        // 확장 상태에서는 탭 버튼으로 동작
                        TabStatItem(
                            tab: .memories,
                            count: memoryCount,
                            isSelected: selectedTab == .memories,
                            onTap: { onTabSelected(.memories) }
                        )
                        TabStatItem(
                            tab: .comments,
                            count: commentCount,
                            isSelected: selectedTab == .comments,
                            onTap: { onTabSelected(.comments) }
                        )
                        TabStatItem(
                            tab: .likes,
                            count: likeCount,
                            isSelected: selectedTab == .likes,
                            onTap: { onTabSelected(.likes) }
                        )
                    } else {
                        // 축소 상태에서는 일반 스탯 아이템
                        StatItem(icon: "Memory-icon", count: memoryCount)
                        StatItem(icon: "CommentIcon", count: commentCount)
                        StatItem(icon: "Like-on", count: likeCount)
                    }
                }
                Spacer()
            }
        }
        .onAppear {
            displayName = profile.name
        }
        .onChange(of: profile.name) { _, newName in
            withAnimation(.easeInOut(duration: 0.3)) {
                displayName = newName
            }
            Logger.info("ProfileHeaderStatsView: Profile name updated to: \(newName)")
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

// MARK: - Tab Stat Item
struct TabStatItem: View {
    let tab: ProfileTab
    let count: Int
    let isSelected: Bool
    let onTap: () -> Void
    
    // 선택 상태에 따른 아이콘 결정
    private var displayIcon: String {
        switch tab {
        case .memories:
            return isSelected ? "Memory-icon" : "memoryOff"
        case .comments:
            return isSelected ? "CommentIcon" : "commentOff"
        case .likes:
            return isSelected ? "likeIcon" : "likeOff"
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .center, spacing: 8) {
                Image(displayIcon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18, height: 18)
                    .foregroundColor(isSelected ? Colors.NebulaWhite : Colors.NebulaWhite.opacity(0.5))
                
                Text("\(count)")
                    .fontStyle(Fonts.callout)
                    .foregroundColor(isSelected ? Colors.NebulaWhite : Colors.NebulaWhite.opacity(0.5))
            }
            .frame(minWidth: 60)
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Loading View
struct LoadingView: View {
    var body: some View {
        iOSUnifiedLoadingView.fullscreen()
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
                .fontStyle(Fonts.subheadline)
                .foregroundColor(Colors.NonCheckedBoxStroke)
            
            Button(action: {
                showSortOptions.toggle()
            }) {
                HStack(spacing: 12) {
                    Text(viewModel.sortOption.displayName)
                        .fontStyle(Fonts.subheadline)
                        .foregroundStyle(LinearGradient.IconGradient)
                    
                    Image("dropDownSortIcon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                }
            }
            .padding(.horizontal,12)
            .padding(.vertical, 6)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 40)
                        .fill(
                            Colors.BackgroundBlack.opacity(0.9)
                        )
                    
                    RoundedRectangle(cornerRadius: 40)
                        .fill(
                            LinearGradient.BackgroundPopup
                        )
                }
            )
            .cornerRadius(16)
    
            Spacer()
            
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 20)
        .overlay(
            Group {
                if showSortOptions {
                    VStack {
                        Spacer()
                        
                        ForEach(UserInfoModalViewModel.SortOption.allCases, id: \.self) { option in
                            Button(action: {
                                viewModel.changeSortOption(option)
                                showSortOptions = false
                            }) {
                                HStack {
                                    Text(option.displayName)
                                        .fontStyle(Fonts.subheadline)
                                        .foregroundStyle(option == viewModel.sortOption ? AnyShapeStyle(LinearGradient.IconGradient) : AnyShapeStyle(Colors.NonCheckedBoxStroke))
                                    
                                    Spacer()
                                }
                                .padding(.vertical, 4)
                                .padding(.horizontal, 12)
                            }
                        }
                        
                        Spacer()
                    }
                    .frame(width: 96, height: 80)
                    .background(
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    Colors.BackgroundBlack.opacity(0.9)
                                )
                            
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    LinearGradient.BackgroundPopup
                                )
                        }
                    )
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .inset(by: 0.75)
                            .stroke(Color(red: 0.65, green: 0.91, blue: 1), lineWidth: 1)
                    )
                    .offset(x: 80, y: 60)
                }
            },
            alignment: .topLeading
        )
    }
}


// MARK: - Tab Content View
struct TabContentView: View {
    @Binding var selectedTab: ProfileTab
    @ObservedObject var viewModel: UserInfoModalViewModel
    let selectedCategories: Set<MemoriesTabContentView.MemoryCategory>
    
    var body: some View {
        VStack(spacing: 0) {
            // 탭 콘텐츠를 조건부로 렌더링
            Group {
                switch selectedTab {
                case .memories:
                    MemoriesTabContentView(viewModel: viewModel, selectedCategories: selectedCategories)
                case .comments:
                    CommentsTabContentView(viewModel: viewModel)
                case .likes:
                    LikesTabContentView(viewModel: viewModel)
                }
            }
            .transition(.opacity)
        }
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






