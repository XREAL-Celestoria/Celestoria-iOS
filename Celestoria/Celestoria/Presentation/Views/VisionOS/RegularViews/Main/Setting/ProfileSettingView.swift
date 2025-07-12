//
//  ProfileSettingView.swift
//  Celestoria
//
//  Created by Park Seyoung on 5/25/25.
//

import SwiftUI
import PhotosUI
import os

// MARK: - Profile Setting View
struct ProfileSettingView: View {
    @EnvironmentObject var viewModel: SettingViewModel
    @State private var selectedSection: SettingSection = .profile
    @State private var isEditing = false
    @State private var isProfileImageSelecting = false
    @FocusState private var isNicknameFocused: Bool
    @State private var isImageLoading: Bool = false // 이미지 로드 상태
    @State private var isUpdating: Bool = false    // 업데이트 상태
    @State private var showProfileSelector = false
    
    @State private var nickname: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack {
                Text("Profile")
                    .font(.system(size: 29, weight: .bold))
                    .foregroundColor(.NebulaWhite)
                
                Spacer()
                
                // isEditing에 따라 Done 버튼 표시 여부 정함.
                if isEditing {
                    Button(action: {
                        Task {
                            isUpdating = true
                            await viewModel.updateProfileIfNeeded(
                                newName: nickname,
                                selectedImage: viewModel.selectedImage
                            )
                            isUpdating = false
                            isEditing = false
                        }
                    }) {
                        Text("DONE")
                            .font(.system(size: 29, weight: .bold))
                            .foregroundStyle(LinearGradient.GradientMain)
                    }
                    .buttonStyle(.plain)
                }
            }            
            .padding(.top, 35)
            .padding(.horizontal, 55)
            
            VStack(spacing: 70) {
                ZStack {
                    // 프로필 이미지 뷰
                    profileImageView
                        .scaledToFill()
                        .frame(width: 330, height: 330)
                        .clipShape(Circle())
                        .overlay(
                            // Change Photo 버튼
                            Group {
                                if isEditing {
                                    Circle()
                                        .fill(Color.black.opacity(0.4))
                                        .overlay(
                                            Text("Change Photo")
                                                .font(.system(size: 20, weight: .semibold))
                                                .foregroundColor(.white)
                                        )
                                        .onTapGesture {
                                            showProfileSelector = true
                                        }
                                }
                            }
                        )
                    
                    if isImageLoading || isUpdating {
                        ProgressView()
                            .frame(width: 330, height: 330)
                            .background(Color.black.opacity(0.4))
                            .clipShape(Circle())
                    }
                    
                }
                
                // nickname view
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.Profile)
                        .frame(width: 600, height: 90)
                    
                    // editing 중일때는 textfield로, 아닐때는 text로
                    if isEditing {
                        TextField("Nickname", text: $nickname)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.NebulaWhite)
                            .multilineTextAlignment(.center)
                            .frame(width: 580)
                            .focused($isNicknameFocused)
                    } else {
                        Text(viewModel.profile?.name ?? "User")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.NebulaWhite)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 23)
            
            // Edit을 눌렀을때 isEditing으로 설정
            Button(action: {
                if isEditing {
                    Task {
                        await viewModel.updateProfileIfNeeded(
                            newName: nickname,
                            selectedImage: viewModel.selectedImage
                        )
                        isEditing = false
                    }
                } else {
                    nickname = viewModel.profile?.name ?? ""
                    isEditing = true
                    isNicknameFocused = true
                }
            }) {
                Text("Edit")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(isEditing ? .gray : .primary)
                    .disabled(isEditing)
            }
            .frame(maxWidth: .infinity)
            .buttonStyle(.plain)
            
            Spacer()
        }
        .sheet(isPresented: $showProfileSelector) {
            ProfileSelectorView(viewModel: viewModel, showProfileSelector: $showProfileSelector)
        }
        .onAppear {
            Task {
                isImageLoading = true
                await viewModel.fetchProfile()
                
                let profile = viewModel.profile
                
                if let key = profile?.profileKey, // ✅ 먼저 profileKey를 기준으로 확인
                   let predefined = PredefinedProfileImage.fromKey(key) {
                    print("✅ profileKey = \(key) → \(predefined.rawValue)")
                    viewModel.selectedImage = .predefined(predefined)
                } else if let urlStr = profile?.profileImageURL,
                          let url = URL(string: urlStr) {
                    do {
                        let (data, _) = try await URLSession.shared.data(from: url)
                        if let image = UIImage(data: data) {
                            await MainActor.run {
                                viewModel.selectedImage = .custom(image)
                            }
                        } else {
                            await MainActor.run {
                                viewModel.selectedImage = .predefined(.profile_gray)
                            }
                        }
                    } catch {
                        await MainActor.run {
                            viewModel.selectedImage = .predefined(.profile_gray)
                        }
                    }
                } else {
                    viewModel.selectedImage = .predefined(.profile_gray)
                }
                
                isImageLoading = false
            }
        }
    }

    @ViewBuilder
    var profileImageView: some View {
        switch viewModel.selectedImage {
        case .custom(let uiImage):
            ZStack {
                Image("profile_bg")
                    .resizable()
                    .scaledToFill()
                    .clipShape(Circle())
                    .frame(width: 330, height: 330)

                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 240, height: 240)
                    .clipShape(Circle())
            }
            
        case .predefined(let predefined):
            if let image = UIImage(named: predefined.rawValue) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                if !isImageLoading || !isUpdating {
                    Image("profile_bg")
                        .resizable()
                        .scaledToFill()
                        .clipShape(Circle())
                        .frame(width: 330, height: 330)
                }
            }

        case .none:
            if !isImageLoading || !isUpdating {
                Image("profile_bg")
                    .resizable()
                    .scaledToFill()
                    .clipShape(Circle())
                    .frame(width: 330, height: 330)
            }
        }
    }
}
