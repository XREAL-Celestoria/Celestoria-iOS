//
//  SettingView.swift
//  Celestoria
//
//  Created by Park Seyoung on 1/20/25.
//

import SwiftUI
import PhotosUI

struct SettingView: View {
    @EnvironmentObject var appModel: AppModel
    @EnvironmentObject var settingViewModel: SettingViewModel
    @State private var selectedSection: SettingSection = .profile
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                // 왼쪽 영역 (2)
                LeftSettingView(selectedSection: $selectedSection)
                    .frame(width: geometry.size.width * 0.4)
                
                // 오른쪽 영역 (3)
                RightSettingView(selectedSection: selectedSection)
                    .frame(width: geometry.size.width * 0.6)
            }
        }
        .background(Color.NebulaBlack.ignoresSafeArea())
        .alert("오류", isPresented: $showError) {
            Button("확인", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
}

// MARK: - Left View
private struct LeftSettingView: View {
    @Binding var selectedSection: SettingSection
    @EnvironmentObject var appModel: AppModel
    @EnvironmentObject var settingViewModel: SettingViewModel
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    
    var body: some View {
        VStack(spacing: 20) {
            // 네비게이션 바
            NavigationBar(
                title: "Settings",
                action: {
                    appModel.activeScreen = .main
                },
                buttonImageString: "chevron.left"
            )
            .padding(.horizontal, 4)
            .padding(.top, 4)
            
            Spacer()
                .frame(height: 40)
            
            // 메뉴 버튼들
            VStack(spacing: 24) {
                SettingButton(
                    title: "Profile",
                    isSelected: selectedSection == .profile,
                    action: { selectedSection = .profile }
                )
                
                SettingButton(
                    title: "Thumbnail",
                    isSelected: selectedSection == .thumbnail,
                    action: { selectedSection = .thumbnail }
                )
                
                SettingButton(
                    title: "Account Setting",
                    isSelected: selectedSection == .account,
                    action: { selectedSection = .account }
                )
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
                    .cornerRadius(20)
            }
            .buttonStyle(.plain)
            .padding(.bottom, 40)
        }
        .alert("오류", isPresented: $showError) {
            Button("확인", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
}

// MARK: - Right View
private struct RightSettingView: View {
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
            case .account:
                AccountSettingView()
            }
        }
    }
}

// MARK: - Setting Button
private struct SettingButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: 40) {
                Image(title == "Profile" ? (isSelected ? "settings-profile-on" : "settings-profile-off") :
                      title == "Thumbnail" ? (isSelected ? "settings-thumbnail-on" : "settings-thumbnail-off") :
                      isSelected ? "settings-account-on" : "settings-account-off")
                    .resizable()
                    .frame(width: 40, height: 40)
                Text(title)
                    .font(
                        .system(size: 22, weight: .semibold)
                    )
                    .foregroundStyle(
                        isSelected 
                            ? LinearGradient.GradientMain 
                            : LinearGradient(colors: [.white.opacity(0.6)], startPoint: .leading, endPoint: .trailing)
                    )
            }
            .padding(.leading, 10)
            .padding(.trailing, 20)
            .padding(.vertical, 12)
            .frame(maxWidth: 380, alignment: .leading)
            .background(
                isSelected
                    ? .white.opacity(0.1)
                    : .clear
            )
            .cornerRadius(20)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Profile Setting View
private struct ProfileSettingView: View {
    @State private var isEditing = false
    @State private var nickname = "User Name"
    @State private var profileImage: UIImage? = nil
    @State private var selectedItem: PhotosPickerItem? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Profile")
                .font(.system(size: 29, weight: .bold))
                .foregroundColor(.NebulaWhite)
                .padding(.top, 40)
                .padding(.leading, 40)
            
            VStack(spacing: 20) {
                if isEditing {
                    // 프로필 이미지 선택기
                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        if let profileImage = profileImage {
                            Image(uiImage: profileImage)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 120, height: 120)
                                .clipShape(Circle())
                        } else {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 120, height: 120)
                                .clipShape(Circle())
                        }
                    }
                    .onChange(of: selectedItem) { newItem in
                        Task {
                            if let data = try? await newItem?.loadTransferable(type: Data.self),
                               let image = UIImage(data: data) {
                                profileImage = image
                            }
                        }
                    }
                } else {
                    if let profileImage = profileImage {
                        Image(uiImage: profileImage)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                    }
                }
                
                if isEditing {
                    TextField("Nickname", text: $nickname)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 200)
                } else {
                    Text(nickname)
                        .font(.system(size: 22))
                        .foregroundColor(.NebulaWhite)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 40)
            
            Button(action: {
                withAnimation {
                    isEditing.toggle()
                }
            }) {
                Text(isEditing ? "Save" : "Edit")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(isEditing ? .NebulaBlack : .NebulaWhite)
                    .frame(width: 100, height: 40)
                    .background(
                        isEditing ?
                            AnyShapeStyle(LinearGradient.GradientSub) :
                            AnyShapeStyle(Color.clear)
                    )
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.NebulaWhite.opacity(0.3), lineWidth: isEditing ? 0 : 2)
                    )
            }
            .frame(maxWidth: .infinity)
            
            Spacer()
        }
    }
}

// MARK: - Thumbnail Setting View
private struct ThumbnailSettingView: View {
    @State private var showThumbnailSelector = false
    @State private var selectedThumbnail: Int = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Thumbnail")
                .font(.system(size: 29, weight: .bold))
                .foregroundColor(.NebulaWhite)
                .padding(.top, 40)
                .padding(.leading, 40)
            
            Image("CurrentThumbnail") // 현재 썸네일 이미지
                .resizable()
                .scaledToFit()
                .frame(width: 200, height: 200)
                .cornerRadius(12)
                .frame(maxWidth: .infinity)
                .padding(.top, 40)
            
            Button(action: {
                showThumbnailSelector = true
            }) {
                Text("Edit")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.NebulaWhite)
                    .frame(width: 100, height: 40)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.NebulaWhite.opacity(0.3), lineWidth: 2)
                    )
            }
            .frame(maxWidth: .infinity)
            
            Spacer()
        }
        .sheet(isPresented: $showThumbnailSelector) {
            ThumbnailSelectorView(selectedThumbnail: $selectedThumbnail)
        }
    }
}

// MARK: - Thumbnail Selector View
private struct ThumbnailSelectorView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedThumbnail: Int
    @State private var tempSelection: Int?
    
    let thumbnails = ["thumb1", "thumb2", "thumb3", "thumb4", "thumb5", "thumb6"]
    
    var body: some View {
        VStack {
            // 헤더
            HStack {
                Text("Change Thumbnail")
                    .font(.system(size: 29, weight: .bold))
                    .foregroundColor(.NebulaWhite)
                
                Spacer()
                
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.NebulaWhite)
                        .font(.system(size: 20))
                }
            }
            .padding()
            
            // 썸네일 그리드
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 20), count: 3), spacing: 20) {
                ForEach(0..<6) { index in
                    Image(thumbnails[index])
                        .resizable()
                        .scaledToFit()
                        .frame(height: 120)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(tempSelection == index ? Color.blue : Color.clear, lineWidth: 3)
                        )
                        .onTapGesture {
                            tempSelection = index
                        }
                }
            }
            .padding()
            
            Spacer()
            
            // Save 버튼
            Button(action: {
                if let selection = tempSelection {
                    selectedThumbnail = selection
                    dismiss()
                }
            }) {
                Text("Save")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.NebulaBlack)
                    .frame(width: 200, height: 50)
                    .background(
                        tempSelection != nil ?
                            AnyShapeStyle(LinearGradient.GradientSub) :
                            AnyShapeStyle(Color.gray)
                    )
                    .cornerRadius(12)
            }
            .disabled(tempSelection == nil)
            .padding(.bottom, 40)
        }
        .background(Color.NebulaBlack)
    }
}

// MARK: - Account Setting View
private struct AccountSettingView: View {
    @EnvironmentObject var appModel: AppModel
    @EnvironmentObject var settingViewModel: SettingViewModel
    @State private var showDeleteConfirmation = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Account Setting")
                .font(.system(size: 29, weight: .bold))
                .foregroundColor(.NebulaWhite)
                .padding(.top, 40)
                .padding(.leading, 40)
            
            Button(action: {
                showDeleteConfirmation = true
            }) {
                Text("Delete Account")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.red)
                    .frame(width: 200, height: 50)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.red, lineWidth: 2)
                    )
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 40)
            
            Spacer()
        }
        .alert("Delete Account", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    do {
                        try await settingViewModel.deleteAccount()
                        appModel.activeScreen = .login
                        appModel.userId = nil
                    } catch {
                        errorMessage = error.localizedDescription
                        showError = true
                    }
                }
            }
        } message: {
            Text("Are you sure you want to delete your account? This action cannot be undone.")
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
}

// MARK: - Enums
enum SettingSection {
    case profile
    case thumbnail
    case account
}

#Preview {
    SettingView()
}

