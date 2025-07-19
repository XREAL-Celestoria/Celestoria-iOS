//
//  LeftSettingView.swift
//  Celestoria
//
//  Created by Park Seyoung on 5/25/25.
//

import SwiftUI

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
                    .foregroundColor(.NebulaRed)
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
