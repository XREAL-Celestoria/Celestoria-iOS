//
//  SettingRightView.swift
//  Celestoria
//
//  Created by Park Seyoung on 5/25/25.
//

import SwiftUI

// MARK: - Right View
struct RightSettingView: View {
    let selectedSection: SettingSection
    
    var body: some View {
        ZStack {
            // Background blur layer
            VisualEffectBlur(style: .systemMaterial)
                .edgesIgnoringSafeArea(.all)
            
            // Inner shadow and transparent background
            Rectangle()
                .fill(Color.clear)
                .overlay(
                    Color.NebulaBlack.opacity(0.3)
                        .shadow(.inner(color: Color.NebulaWhite.opacity(0.8), radius: 24))
                )
                .edgesIgnoringSafeArea(.all)
            
            // Content
            switch selectedSection {
            case .profile:
                ProfileSettingView()
            case .thumbnail:
                ThumbnailSettingView()
            case .notifications:
                NotificationsSettingView()
            case .blockedUsers:
                BlockedUsersSettingView()
            case .account:
                AccountSettingView()
            }
        }
    }
}
