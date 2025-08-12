//
//  ProfileImageView.swift
//  Celestoria
//
//  Created by AI Assistant on 2/7/25.
//

import SwiftUI

struct ProfileImageView: View {
    let profile: UserProfile
    let size: CGFloat
    let showBackground: Bool
    let cornerRadius: CGFloat
    
    // 커스텀 이미지 비율 (72.7%)
    private let customImageRatio: CGFloat = 0.727
    
    init(
        profile: UserProfile,
        size: CGFloat,
        showBackground: Bool = true,
        cornerRadius: CGFloat? = nil
    ) {
        self.profile = profile
        self.size = size
        self.showBackground = showBackground
        
        // cornerRadius가 nil이면 size에 따라 자동 계산
        if let cornerRadius = cornerRadius {
            self.cornerRadius = cornerRadius
        } else {
            self.cornerRadius = size / 2 // 원형
        }
    }
    
    var body: some View {
        if let key = profile.profileKey,
           let predefined = PredefinedProfileImage.fromKey(key) {
            // 프리디파인드 이미지 (배경 없음)
            Image(predefined.rawValue)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        } else if let url = profile.profileImageURL {
            // 커스텀 이미지
            if showBackground {
                // 배경과 함께 표시
                ZStack {
                    // 배경 이미지
                    Image("profile_bg")
                        .resizable()
                        .scaledToFill()
                        .frame(width: size, height: size)
                        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                    
                    // 커스텀 프로필 이미지 (72.7% 크기)
                    AsyncImage(url: URL(string: url)) { image in
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(
                                width: size * customImageRatio,
                                height: size * customImageRatio
                            )
                            .clipShape(RoundedRectangle(cornerRadius: cornerRadius * customImageRatio))
                    } placeholder: {
                        // 로딩 중 플레이스홀더
                        RoundedRectangle(cornerRadius: cornerRadius * customImageRatio)
                            .fill(Colors.NebulaBlack.opacity(0.3))
                            .frame(
                                width: size * customImageRatio,
                                height: size * customImageRatio
                            )
                    }
                }
            } else {
                // 배경 없이 커스텀 이미지만 표시
                AsyncImage(url: URL(string: url)) { image in
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: size, height: size)
                        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                } placeholder: {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(Colors.NebulaBlack.opacity(0.3))
                        .frame(width: size, height: size)
                }
            }
        } else {
            // 기본 이미지 (프로필 키나 URL이 없는 경우)
            Image("profile_gray")
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        }
    }
}

// MARK: - 편의 이니셜라이저들
extension ProfileImageView {
    // 원형 프로필 이미지 (기본)
    static func circular(
        profile: UserProfile,
        size: CGFloat,
        showBackground: Bool = true
    ) -> ProfileImageView {
        ProfileImageView(
            profile: profile,
            size: size,
            showBackground: showBackground,
            cornerRadius: size / 2
        )
    }
    
    // 둥근 모서리 프로필 이미지
    static func rounded(
        profile: UserProfile,
        size: CGFloat,
        cornerRadius: CGFloat,
        showBackground: Bool = true
    ) -> ProfileImageView {
        ProfileImageView(
            profile: profile,
            size: size,
            showBackground: showBackground,
            cornerRadius: cornerRadius
        )
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        // 원형 프로필 이미지들
        HStack(spacing: 20) {
            ProfileImageView.circular(
                profile: UserProfile(
                    userId: UUID(),
                    name: "Blue User",
                    profileKey: "blue",
                    profileImageURL: nil,
                    spaceThumbnailId: "1"
                ),
                size: 60
            )
            
            ProfileImageView.circular(
                profile: UserProfile(
                    userId: UUID(),
                    name: "Custom User",
                    profileKey: nil,
                    profileImageURL: "https://example.com/profile.jpg",
                    spaceThumbnailId: "2"
                ),
                size: 60
            )
            
            ProfileImageView.circular(
                profile: UserProfile(
                    userId: UUID(),
                    name: "Default User",
                    profileKey: nil,
                    profileImageURL: nil,
                    spaceThumbnailId: "3"
                ),
                size: 60
            )
        }
        
        // 둥근 모서리 프로필 이미지들
        HStack(spacing: 20) {
            ProfileImageView.rounded(
                profile: UserProfile(
                    userId: UUID(),
                    name: "Green User",
                    profileKey: "green",
                    profileImageURL: nil,
                    spaceThumbnailId: "4"
                ),
                size: 80,
                cornerRadius: 20
            )
            
            ProfileImageView.rounded(
                profile: UserProfile(
                    userId: UUID(),
                    name: "Custom Rounded User",
                    profileKey: nil,
                    profileImageURL: "https://example.com/profile.jpg",
                    spaceThumbnailId: "5"
                ),
                size: 80,
                cornerRadius: 20
            )
        }
    }
    .padding()
    .background(Colors.backgroundMain)
}
