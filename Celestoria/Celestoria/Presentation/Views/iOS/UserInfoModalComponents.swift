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
    
    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            ProfileImageView(profile: profile, size: 32)
            
            Text(profile.name)
                .fontStyle(Fonts.title3)
                .foregroundColor(Colors.NebulaWhite)
                .lineLimit(1)
            
            Spacer()
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Profile Image View
struct ProfileImageView: View {
    let profile: UserProfile
    let size: CGFloat
    
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
                AsyncImage(url: URL(string: profileImageURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: size))
                        .foregroundColor(.gray)
                }
                .onAppear {
                    Logger.info("ProfileImageView: Using custom image - URL: \(profileImageURL)")
                }
            } else {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: size))
                    .foregroundColor(.gray)
                    .onAppear {
                        Logger.info("ProfileImageView: Using fallback image - profileKey: \(profile.profileKey ?? -1), imageURL: \(profile.profileImageURL ?? "nil")")
                    }
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
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
