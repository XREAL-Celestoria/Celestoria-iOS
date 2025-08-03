//
//  SettingView.swift
//  Celestoria
//
//  Created by Park Seyoung on 1/20/25.
//

import SwiftUI
import PhotosUI

enum SettingSection: String {
    case profile = "Profile"
    case thumbnail = "Thumbnail"
    case blockedUsers = "Blocked Users"
    case account = "Account"
}

struct SettingView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var settingViewModel: SettingViewModel
    @State private var selectedSection: SettingSection = .profile
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                LeftSettingView(selectedSection: $selectedSection)
                    .frame(width: geometry.size.width * 0.38)
                
                RightSettingView(selectedSection: selectedSection)
                    .frame(width: geometry.size.width * 0.62)
            }
        }
        .background(Colors.NebulaBlack.ignoresSafeArea())
        .alert("오류", isPresented: $showError) {
            Button("확인", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .onChange(of: scenePhase) { newPhase in
            switch newPhase {
            case .background, .inactive:
                appState.isImmersiveViewActive = false
            case .active:
                if appState.userId != nil && !appState.isImmersiveViewActive {
                    Task {
                        await openImmersiveSpace(id: appState.immersiveSpaceID)
                        appState.isImmersiveViewActive = true
                    }
                }
            default:
                break
            }
        }
    }
}

// MARK: - Left View
struct LeftSettingView: View {
    @Binding var selectedSection: SettingSection
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var settingViewModel: SettingViewModel
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    
    var body: some View {
        VStack(spacing: 20) {
            // 네비게이션 바
            NavigationBar(
                title: "Settings",
                action: {
                    appState.activeScreen = .main
                },
                buttonImageString: "chevron.left"
            )
            .padding(.horizontal, 4)
            .padding(.top, 4)
            
            Spacer()
                .frame(height: 20)
            
            // 메뉴 버튼들
            VStack(spacing: 24) {
                ForEach(settingsMenuItems, id: \.title) { item in
                    NavigationMenuButton(
                        menuItem: item,
                        isSelected: selectedSection.rawValue == item.title,
                        action: {
                            if let section = SettingSection(rawValue: item.title) {
                                selectedSection = section
                            }
                        }
                    )
                }
            }
            
            Spacer()
            
            // Sign Out 버튼
            Button(action: {
                Task {
                    do {
                        try await settingViewModel.signOut()
                    } catch {
                        errorMessage = error.localizedDescription
                        showError = true
                    }
                }
            }) {
                Text("Sign Out")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(Colors.NebulaRed)
                    .padding(.vertical, 18)
                    .frame(maxWidth: 380, alignment: .center)
                    .background(Color(hex: "#1B212A"))
            }
            .buttonStyle(.plain)
            .cornerRadius(20)
            .padding(.bottom, 50)
        }
        .alert("오류", isPresented: $showError) {
            Button("확인", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
}

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
                    Colors.NebulaBlack.opacity(0.3)
                        .shadow(.inner(color: Colors.NebulaWhite.opacity(0.8), radius: 24))
                )
                .edgesIgnoringSafeArea(.all)
            
            // Content
            switch selectedSection {
            case .profile:
                ProfileSettingView()
            case .thumbnail:
                ThumbnailSettingView()
            case .blockedUsers:
                BlockedUsersSettingView()
            case .account:
                AccountSettingView()
            }
        }
    }
}
