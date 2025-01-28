//
//  SettingView.swift
//  Celestoria
//
//  Created by Park Seyoung on 1/20/25.
//

import SwiftUI
import PhotosUI

// MARK: - Button Styles
private struct NoEffectButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
    }
}

struct SettingView: View {
    @EnvironmentObject var appModel: AppModel
    @EnvironmentObject var settingViewModel: SettingViewModel
    @State private var selectedSection: SettingSection = .profile
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                LeftSettingView(selectedSection: $selectedSection)
                    .frame(width: geometry.size.width * 0.38)
                
                RightSettingView(selectedSection: selectedSection)
                    .frame(width: geometry.size.width * 0.62)
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
                    .cornerRadius(20)
            }
            .buttonStyle(.plain)
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

// MARK: - Profile Setting View
private struct ProfileSettingView: View {
    @EnvironmentObject var viewModel: SettingViewModel
    @State private var isEditing = false
    @State private var nickname: String = ""
    @State private var profileImage: UIImage? = nil
    @State private var selectedItem: PhotosPickerItem? = nil
    @FocusState private var isNicknameFocused: Bool
    @State private var isImageLoading: Bool = false // 이미지 로드 상태
    @State private var isUpdating: Bool = false    // 업데이트 상태

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack {
                Text("Profile")
                    .font(.system(size: 29, weight: .bold))
                    .foregroundColor(.NebulaWhite)

                Spacer()

                if isEditing {
                    Button(action: {
                        Task {
                            isUpdating = true
                            await viewModel.updateProfile(name: nickname, image: profileImage)
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
                        .frame(width: 330, height: 330)
                        .clipShape(Circle())

                    // 이미지 로드 또는 업데이트 중일 때 ProgressView 표시
                    if isImageLoading || isUpdating {
                        ProgressView()
                            .frame(width: 330, height: 330)
                            .background(Color.black.opacity(0.4))
                            .clipShape(Circle())
                    }

                    if isEditing {
                        // 이미지 선택기
                        PhotosPicker(selection: $selectedItem, matching: .images) {
                            Circle()
                                .fill(Color.black.opacity(0.5))
                                .frame(width: 330, height: 330)
                                .overlay(
                                    Text("Change Photo")
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundColor(.white)
                                )
                        }
                        .buttonStyle(.plain)
                        .onChange(of: selectedItem) { newItem in
                            Task {
                                if let data = try? await newItem?.loadTransferable(type: Data.self),
                                   let image = UIImage(data: data) {
                                    await MainActor.run {
                                        profileImage = image
                                    }
                                }
                            }
                        }
                    }
                }

                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.Profile)
                        .frame(width: 600, height: 90)

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

            Button(action: {
                withAnimation {
                    if isEditing {
                        Task {
                            await viewModel.updateProfile(name: nickname, image: profileImage)
                            isEditing = false
                        }
                    } else {
                        nickname = viewModel.profile?.name ?? ""
                        isEditing = true
                        isNicknameFocused = true
                    }
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
        .onAppear {
            Task {
                isImageLoading = true // 로딩 시작
                await viewModel.fetchProfile()
                nickname = viewModel.profile?.name ?? ""

                if let profileURL = viewModel.profile?.profileImageURL, let url = URL(string: profileURL) {
                    do {
                        let (data, _) = try await URLSession.shared.data(from: url)
                        if let image = UIImage(data: data) {
                            await MainActor.run {
                                profileImage = image
                            }
                        } else {
                            await MainActor.run {
                                profileImage = UIImage(named: "ProfileImage")
                            }
                        }
                    } catch {
                        await MainActor.run {
                            profileImage = UIImage(named: "ProfileImage")
                        }
                    }
                } else {
                    profileImage = UIImage(named: "ProfileImage")
                }

                isImageLoading = false // 로딩 완료
            }
        }
    }

    @ViewBuilder
    private var profileImageView: some View {
        if let profileImage = profileImage {
            Image(uiImage: profileImage)
                .resizable()
                .scaledToFill()
        } else {
            Image("ProfileImage")
                .resizable()
                .scaledToFill()
        }
    }
}


// MARK: - Thumbnail Setting View
private struct ThumbnailSettingView: View {
    @EnvironmentObject var viewModel: SettingViewModel
    @State private var showThumbnailSelector = false
    @State private var selectedThumbnail: Int = 0
    @State private var isEditing = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 40) {
            Text("Thumbnail")
                .font(.system(size: 29, weight: .bold))
                .foregroundColor(.NebulaWhite)
                .padding(.top, 35)
                .padding(.horizontal, 55)
            
            Button(action: {
                if isEditing {
                    showThumbnailSelector = true
                }
            }) {
                ZStack {
                    Image(viewModel.getThumbnailImageName(from: viewModel.profile?.spaceThumbnailId))
                        .resizable()
                        .scaledToFill()
                        .frame(width: 434, height: 456)
                        .cornerRadius(19)
                    if isEditing {
                        // 오버레이 레이어
                        RoundedRectangle(cornerRadius: 19)
                            .fill(Color.black.opacity(0.5))
                            .frame(width: 434, height: 456)
                        
                        // Change Photo 텍스트
                        Text("Change Photo")
                            .font(.system(size: 29, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity)
            .padding(.top, 20)
            
            Button(action: {
                isEditing.toggle()
            }) {
                Text(isEditing ? "Cancel" : "Edit")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.NebulaWhite)
            }
            .frame(maxWidth: .infinity)
            .buttonStyle(.plain)
            
            Spacer()
        }
        .sheet(isPresented: $showThumbnailSelector) {
            ThumbnailSelectorView(
                selectedThumbnail: $selectedThumbnail,
                isPresented: $showThumbnailSelector,
                isEditing: $isEditing,
                viewModel: viewModel
            )
        }
        .onAppear {
            if let currentId = viewModel.profile?.spaceThumbnailId,
               let intId = Int(currentId) {
                selectedThumbnail = intId - 1
            }
        }
    }
}

// MARK: - Thumbnail Selector View
private struct ThumbnailSelectorView: View {
    @Binding var selectedThumbnail: Int
    @Binding var isPresented: Bool
    @Binding var isEditing: Bool
    @State private var initialThumbnail: Int
    let viewModel: SettingViewModel
    
    let thumbnails = ["Thumbnail1", "Thumbnail2", "Thumbnail3", "Thumbnail4", "Thumbnail5", "Thumbnail6"]
    
    init(selectedThumbnail: Binding<Int>, isPresented: Binding<Bool>, isEditing: Binding<Bool>, viewModel: SettingViewModel) {
        self._selectedThumbnail = selectedThumbnail
        self._isPresented = isPresented
        self._isEditing = isEditing
        self._initialThumbnail = State(initialValue: selectedThumbnail.wrappedValue)
        self.viewModel = viewModel
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 50) {
                HStack {
                    Text("Change Thumbnail")
                        .font(.system(size: 29, weight: .bold))
                        .foregroundColor(.NebulaWhite)
                    
                    Spacer()
                    
                    Button(action: {
                        isPresented = false
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color(hex: "E7E7E7").opacity(0.2))
                                .frame(width: 44, height: 44)
                            
                            Image(systemName: "xmark")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20, height: 20)
                                .foregroundColor(.NebulaWhite)
                        }
                    }
                    .buttonStyle(MainButtonStyle())
                }
                .padding(.horizontal, 60)
                .padding(.top, 40)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 20), count: 3), spacing: 20) {
                    ForEach(0..<6) { index in
                        Button(action: {
                            selectedThumbnail = index
                        }) {
                            ThumbnailCell(
                                image: thumbnails[index],
                                isSelected: selectedThumbnail == index
                            )
                        }
                        .buttonStyle(NoEffectButtonStyle())
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                            .inset(by: 0.25)
                            .stroke(Color(red: 0.62, green: 0.62, blue: 0.62), lineWidth: 0.5)
                        )
                    }
                }
                .padding(.horizontal, 60)
                .padding(.top, 20)
                
                Button(action: {
                    Task {
                        // Convert thumbnail index to ID (adding 1 because IDs start from 1)
                        await viewModel.updateThumbnail(thumbnailId: String(selectedThumbnail + 1))
                        isPresented = false
                        isEditing = false
                    }
                }) {
                    Text("SAVE")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(selectedThumbnail != initialThumbnail ? .black : .black.opacity(0.3))
                        .frame(maxWidth: .infinity)
                        .frame(height: 76)
                        .background(
                            selectedThumbnail != initialThumbnail ?
                            LinearGradient(
                                stops: [
                                    Gradient.Stop(color: Color(red: 0.65, green: 0.91, blue: 1), location: 0.00),
                                    Gradient.Stop(color: Color(red: 0.71, green: 0.79, blue: 1), location: 1.00),
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            ) :
                            LinearGradient(
                                stops: [
                                    Gradient.Stop(color: Color(red: 0.67, green: 0.72, blue: 0.78), location: 0.00),
                                    Gradient.Stop(color: Color(red: 0.51, green: 0.62, blue: 0.73), location: 1.00),
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .cornerRadius(16)
                }
                .disabled(selectedThumbnail == initialThumbnail)
                .padding(.horizontal, 60)
                .padding(.bottom, 40)
                .buttonStyle(.plain)
            }
        }
        .frame(width: 778, height: 849)
        .background(
            LinearGradient(
                stops: [
                    Gradient.Stop(color: Color(hex: "17191E"), location: 0.00),
                    Gradient.Stop(color: Color(hex: "17191E"), location: 0.66),
                    Gradient.Stop(color: Color(red: 0.33, green: 0.77, blue: 1).opacity(0.5), location: 1.00),
                ],
                startPoint: UnitPoint(x: 0.5, y: 0),
                endPoint: UnitPoint(x: 0.5, y: 1)
            )
        )
        .cornerRadius(46)
        .shadow(color: Color(red: 0.42, green: 0.73, blue: 1), radius: 15)
        // 이 윈도우는 stroke가 얇아서 GradientBorderContainer 이거 당장은 못 씀
        .overlay(
            RoundedRectangle(cornerRadius: 46)
                .inset(by: 1.5)
                .stroke(.white, lineWidth: 3)
        )
    }
}

// MARK: - Thumbnail Cell
private struct ThumbnailCell: View {
    let image: String
    let isSelected: Bool
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topTrailing) {
                // Base Image
                Image(image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                
                // Overlay when selected
                if isSelected {
                    Color.black.opacity(0.5)
                    
                    // Check Circle
                    Image("Check-Circle")
                        .frame(width: 30, height: 30)
                        .padding([.top, .trailing], 12)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .frame(width: 210, height: 240)
    }
}

// MARK: - Account Setting View
private struct AccountSettingView: View {
    @EnvironmentObject var appModel: AppModel
    @EnvironmentObject var settingViewModel: SettingViewModel
    @State private var showDeleteConfirmation = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isHovered = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Account Setting")
                .font(.system(size: 29, weight: .bold))
                .foregroundColor(.NebulaWhite)
                .padding(.top, 35)
                .padding(.horizontal, 55)
            
            Button(action: {
                showDeleteConfirmation = true
            }) {
                HStack(alignment: .center, spacing: 40) {
                    Text("Delete Account")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(colors: [.white], startPoint: .leading, endPoint: .trailing)
                        )
                }
                .padding(.vertical, 18)
                .padding(.horizontal, 20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    Color.white.opacity(0.1)
                        .opacity(isHovered ? 1 : 0)
                )
                .cornerRadius(20)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 35)
            .padding(.top, 30)
            .onHover { hovering in
                isHovered = hovering
            }
            
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
enum SettingSection: String {
    case profile = "Profile"
    case thumbnail = "Thumbnail"
    case account = "Account"
}

#Preview {
    SettingView()
}

