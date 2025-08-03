//
//  iOSProfileSettingView.swift
//  Celestoria
//
//  Created by Minjun Kim on 7/20/25.
//


import SwiftUI
import PhotosUI

struct iOSProfileSettingView: View {
    @StateObject private var settingViewModel: SettingViewModel
    @State private var showProfileSelector = false
    @State private var tempNickname = ""
    @State private var isImageLoading = false
    @State private var isUpdating = false
    @FocusState private var isNicknameFocused: Bool
    @Environment(\.dismiss) private var dismiss
    let diContainer: DIContainer
    
    init(diContainer: DIContainer) {
        self.diContainer = diContainer
        _settingViewModel = StateObject(wrappedValue: diContainer.settingViewModel)
    }
    
    var body: some View {
        ZStack {
            // Background
            Colors.BackgroundBlack
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Profile Image Section
                VStack(spacing: 36) {
                    ZStack {
                        // 프로필 이미지 뷰
                        profileImageView
                            .scaledToFill()
                            .frame(width: 220, height: 220)
                            .clipShape(Circle())
                            .onTapGesture {
                                showProfileSelector = true
                            }
                    }
                    
                    // Nickname Section - styled like visionOS
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Colors.ProfileNamebox)
                            .frame(width: UIScreen.main.bounds.width - 48, height: 84)
                            .overlay(nicknameStroke)
                        
                        TextField("Nickname", text: $tempNickname)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(Colors.NebulaWhite)
                            .multilineTextAlignment(.center)
                            .frame(width: UIScreen.main.bounds.width - 52)
                            .focused($isNicknameFocused)
                    }
                    .onTapGesture {
                        isNicknameFocused = true
                    }
                }
                .padding(.top, 30)
                
                Spacer()
                
                // Save Button - fixed at bottom
                iOSUploadButton (
                    title: "Save",
                    action: {
                        // 키보드 내리기
                        isNicknameFocused = false
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        
                        Task {
                            isUpdating = true
                            await settingViewModel.updateProfileIfNeeded(newName: tempNickname, selectedImage: settingViewModel.selectedImage)
                            isUpdating = false
                            dismiss()
                        }
                    },
                    isEnabled: hasChanges
                )
                .padding(.horizontal, 24)
                .padding(.bottom, 30)
                .background(LinearGradient.BtnBackGrad)
            }
            .onTapGesture {
                // 배경을 탭했을 때 키보드 내리기
                isNicknameFocused = false
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
        }
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    // 키보드 내리기
                    isNicknameFocused = false
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    dismiss()
                }) {
                    Image("backButton")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                }
            }
        }
        .sheet(isPresented: $showProfileSelector) {
            iOSProfileSelectorView(settingViewModel: settingViewModel, isPresented: $showProfileSelector)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .overlay(
            // Loading overlay - 맨 위에 정 가운데
            Group {
                if isImageLoading || isUpdating {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                    
                    VStack {
                        Spacer()
                        LoadingView()
                        Spacer()
                    }
                    .frame(maxWidth: UIScreen.main.bounds.width , maxHeight: .infinity)
                }
            }
        )
        .task {
            Task {
                isImageLoading = true
                await settingViewModel.fetchProfile()
                
                let profile = settingViewModel.profile
                
                // tempNickname 초기화
                tempNickname = profile?.name ?? ""
                
                if let key = profile?.profileKey,
                   let predefined = PredefinedProfileImage.fromKey(key) {
                    print("✅ profileKey = \(key) → \(predefined.rawValue)")
                    settingViewModel.selectedImage = .predefined(predefined)
                } else if let urlStr = profile?.profileImageURL {
                    // SettingViewModel에서 이미 캐시된 이미지가 있는지 확인
                    if let selectedImage = settingViewModel.selectedImage,
                       case .custom(let image) = selectedImage {
                        // 이미 캐시된 이미지가 있으면 그대로 사용
                        print("✅ 캐시된 커스텀 이미지 사용")
                    } else {
                        // SettingViewModel에서 이미지 로드 (캐싱 포함)
                        await settingViewModel.fetchProfile()
                    }
                } else {
                    settingViewModel.selectedImage = .predefined(.profile_gray)
                }
                
                isImageLoading = false
            }
        }
    }
    
    // 변경사항이 있는지 확인하는 computed property
    private var hasChanges: Bool {
        let nameChanged = tempNickname != (settingViewModel.profile?.name ?? "")
        let imageChanged = settingViewModel.selectedImage != settingViewModel.originalImage
        return nameChanged || imageChanged
    }
    
    @ViewBuilder
    var profileImageView: some View {
        switch settingViewModel.selectedImage {
        case .custom(let uiImage):
            ZStack {
                Image("profile_bg")
                    .resizable()
                    .scaledToFill()
                    .clipShape(Circle())
                    .frame(width: 220, height: 220)
                
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 160, height: 160)
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
                        .frame(width: 220, height: 220)
                }
            }
            
        case .none:
            if !isImageLoading || !isUpdating {
                Image("profile_bg")
                    .resizable()
                    .scaledToFill()
                    .clipShape(Circle())
                    .frame(width: 220, height: 220)
            }
        }
    }
    
    @ViewBuilder
    private var nicknameStroke: some View {
        RoundedRectangle(cornerRadius: 16)
            .stroke(
                isNicknameFocused ? AnyShapeStyle(LinearGradient.GradientSub) : AnyShapeStyle(Color.clear),
                lineWidth: isNicknameFocused ? 2 : 0
            )
    }
}


struct iOSProfileSelectorView: View {
    @ObservedObject var settingViewModel: SettingViewModel
    @Binding var isPresented: Bool
    @State private var selectedItem: PhotosPickerItem?
    @State private var tempSelectedImage: ProfileImageSelection?
    
    private let predefinedImages = PredefinedProfileImage.allCases
    
    var body: some View {
        ZStack {
            Color(hex: "262629")
                .ignoresSafeArea()
            
            VStack {
                // Grid of profile images
                ScrollView {
                    Spacer()
                        .frame(height: 20)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        
                        PhotoPickerView(
                            selectedItem: $selectedItem,
                            tempSelectedImage: $tempSelectedImage,
                            isSelected: {
                                if let temp = tempSelectedImage {
                                    if case .custom = temp {
                                        return true
                                    }
                                }
                                return false
                            }()
                        )
                        .onChange(of: selectedItem) { _, newItem in
                            Task {
                                if let data = try? await newItem?.loadTransferable(type: Data.self),
                                   let image = UIImage(data: data) {
                                    await MainActor.run {
                                        tempSelectedImage = .custom(image)
                                        // 커스텀 이미지 선택 시 바로 적용하고 닫기
                                        settingViewModel.selectedImage = .custom(image)
                                        isPresented = false
                                    }
                                }
                            }
                        }
                        
                        // Predefined profile images
                        ForEach(predefinedImages, id: \.self) { predefinedImage in
                            Button(action: {
                                tempSelectedImage = .predefined(predefinedImage)
                                // 미리 정의된 이미지 선택 시 바로 적용하고 닫기
                                settingViewModel.selectedImage = .predefined(predefinedImage)
                                isPresented = false
                            }) {
                                ProfileCell(
                                    image: predefinedImage.rawValue,
                                    isSelected: isImageSelected(predefinedImage)
                                )
                            }
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 60)
                }
            }
        }
        .onAppear {
            // 현재 선택된 이미지를 tempSelectedImage로 설정
            tempSelectedImage = settingViewModel.selectedImage
        }
    }
    
    private func isImageSelected(_ predefinedImage: PredefinedProfileImage) -> Bool {
        if let temp = tempSelectedImage {
            if case .predefined(let selected) = temp {
                return selected == predefinedImage
            }
        }
        return false
    }
}

// MARK: - Profile Cell
struct ProfileCell: View {
    let image: String
    let isSelected: Bool
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Base Image
            if let uiImage = UIImage(named: image) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
            } else {
                // Fallback image
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 100, height: 100)
            }
            
            // Selection overlay
            if isSelected {
                Circle()
                    .stroke(
                        LinearGradient.GradientSub,
                        lineWidth: 2
                    )
                    .frame(width: 100, height: 100)
                
                // Check mark
                Image("Check-Circle")
                    .resizable()
                    .frame(width: 20, height: 20)
                    .offset(x: -2, y: 2)
            }
        }
        .frame(width: 100, height: 100)
    }
}

// MARK: - PhotoPickerView
struct PhotoPickerView: View {
    @Binding var selectedItem: PhotosPickerItem?
    @Binding var tempSelectedImage: ProfileImageSelection?
    let isSelected: Bool
    
    var body: some View {
        PhotosPicker(selection: $selectedItem, matching: .images) {
            ZStack {
                if case .custom(let image) = tempSelectedImage {
                    Image("profile_bg")
                        .resizable()
                        .scaledToFill()
                        .clipShape(Circle())
                        .frame(width: 80, height: 80)
                    
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 60, height: 60)
                        .clipShape(Circle())
                    
                    Circle()
                        .fill(.black.opacity(0.2))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Colors.NebulaWhite.opacity(0.5))
                    
                    if isSelected {
                        Circle()
                            .stroke(
                                LinearGradient.GradientSub,
                                lineWidth: 2
                            )
                            .frame(width: 80, height: 80)
                        
                        // Check mark
                        Image("Check-Circle")
                            .resizable()
                            .frame(width: 20, height: 20)
                            .offset(x: 30, y: -30)
                    }
                    
                } else {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                        .frame(width: 80, height: 80)
                        .background(.clear)
                    
                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Colors.NebulaWhite.opacity(0.5))
                }
            }
        }
    }
}

// Profile Image Cell
struct ProfileImageCell: View {
    let imageName: String
    let isSelected: Bool
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Profile Image
            Image(imageName)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 100, height: 100)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(
                            isSelected ? LinearGradient.GradientMain : LinearGradient(colors: [Color.clear], startPoint: .top, endPoint: .bottom),
                            lineWidth: isSelected ? 3 : 0
                        )
                )
            
            // Checkmark
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(.white, LinearGradient.GradientMain)
                    .background(Circle().fill(Color.black))
                    .offset(x: -5, y: 5)
            }
        }
        .frame(width: 100, height: 100)
    }
}


