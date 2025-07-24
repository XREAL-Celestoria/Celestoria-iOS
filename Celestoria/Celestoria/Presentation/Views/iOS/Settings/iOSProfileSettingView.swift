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
    @State private var isEditMode = false
    @State private var showProfileSelector = false
    @State private var tempNickname = ""
    let diContainer: DIContainer
    
    init(diContainer: DIContainer) {
        self.diContainer = diContainer
        _settingViewModel = StateObject(wrappedValue: diContainer.settingViewModel)
    }
    
    var body: some View {
        ZStack {
            // Background
            Color.black
                .ignoresSafeArea()
            
            VStack {
                ScrollView {
                    VStack(spacing: 24) {
                        // Profile Image Section
                        VStack(spacing: 16) {
                            ZStack {
                        if let profileKey = settingViewModel.profile?.profileKey,
                           let predefinedImage = PredefinedProfileImage.fromKey(profileKey) {
                            // Show predefined profile image
                            Image(predefinedImage.rawValue)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 150, height: 150)
                                .clipShape(Circle())
                        } else if let profileImageUrl = settingViewModel.profile?.profileImageURL {
                            AsyncImage(url: URL(string: profileImageUrl)) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Circle()
                                    .fill(Color.gray.opacity(0.3))
                                    .overlay(
                                        ProgressView()
                                    )
                            }
                            .frame(width: 150, height: 150)
                            .clipShape(Circle())
                        } else {
                            Circle()
                                .fill(LinearGradient.GradientMain)
                                .frame(width: 150, height: 150)
                                .overlay(
                                    Text(settingViewModel.profile?.name.prefix(1).uppercased() ?? "?")
                                        .font(.system(size: 60, weight: .bold))
                                        .foregroundColor(Colors.NebulaBlack)
                                )
                        }
                        
                        if isEditMode {
                            Circle()
                                .fill(Color.black.opacity(0.5))
                                .frame(width: 150, height: 150)
                                .overlay(
                                    VStack {
                                        Image(systemName: "camera.fill")
                                            .font(.system(size: 30))
                                            .foregroundColor(.white)
                                        Text("Change Photo")
                                            .font(.system(size: 14))
                                            .foregroundColor(.white)
                                    }
                                )
                                .onTapGesture {
                                    showProfileSelector = true
                                }
                        }
                    }
                    
                    // Nickname Section - styled like visionOS
                    if isEditMode {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 280, height: 50)
                            
                            TextField("Nickname", text: $tempNickname)
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .frame(width: 260)
                        }
                    } else {
                        Text(settingViewModel.profile?.name ?? "Unknown")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                        .padding(.top, 20)
                        
                        Spacer(minLength: 100) // Space for button
                    }
                    .padding()
                }
                
                // Edit/Save Button - fixed at bottom
                Button(action: {
                    if isEditMode {
                        // Save changes
                        Task {
                            await settingViewModel.updateProfileIfNeeded(newName: tempNickname, selectedImage: settingViewModel.selectedImage)
                            isEditMode = false
                        }
                    } else {
                        // Enter edit mode
                        tempNickname = settingViewModel.profile?.name ?? ""
                        isEditMode = true
                    }
                }) {
                    Text(isEditMode ? "Done" : "Edit")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.NebulaBlack)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(LinearGradient.GradientSub)
                        )
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showProfileSelector) {
            iOSProfileSelectorView(settingViewModel: settingViewModel, isPresented: $showProfileSelector)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .task {
            await settingViewModel.fetchProfile()
        }
    }
}

struct iOSProfileSelectorView: View {
    @ObservedObject var settingViewModel: SettingViewModel
    @Binding var isPresented: Bool
    @State private var selectedItem: PhotosPickerItem?
    @State private var tempSelectedImage: ProfileImageSelection?
    
    private let predefinedImages = PredefinedProfileImage.allCases
    
    private var currentSelectedImage: ProfileImageSelection? {
        if let profileKey = settingViewModel.profile?.profileKey,
           let predefinedImage = PredefinedProfileImage.fromKey(profileKey) {
            return .predefined(predefinedImage)
        }
        return nil
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.NebulaBlack
                    .ignoresSafeArea()
                
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                        // Custom Photo Picker (Plus button)
                        PhotosPicker(selection: $selectedItem, matching: .images) {
                            ZStack {
                                Circle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(width: 100, height: 100)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                    )
                                
                                Image(systemName: "plus")
                                    .font(.system(size: 30))
                                    .foregroundColor(.gray)
                            }
                        }
                        .onChange(of: selectedItem) { _, newItem in
                            if let item = newItem {
                                Task {
                                    if let data = try? await item.loadTransferable(type: Data.self),
                                       let image = UIImage(data: data) {
                                        await MainActor.run {
                                            tempSelectedImage = .custom(image)
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Predefined Images
                        ForEach(predefinedImages, id: \.self) { predefinedImage in
                            Button(action: {
                                tempSelectedImage = .predefined(predefinedImage)
                            }) {
                                ProfileImageCell(
                                    imageName: predefinedImage.rawValue,
                                    isSelected: isImageSelected(predefinedImage)
                                )
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)
                    .padding(.bottom, 100)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        if let tempImage = tempSelectedImage {
                            settingViewModel.selectedImage = tempImage
                            isPresented = false
                            // Update profile after sheet dismisses
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                Task {
                                    await settingViewModel.updateProfileIfNeeded(newName: nil, selectedImage: tempImage)
                                }
                            }
                        }
                    }
                    .foregroundColor(.white)
                    .fontWeight(.semibold)
                    .disabled(tempSelectedImage == nil)
                }
            }
        }
        .onAppear {
            tempSelectedImage = currentSelectedImage
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
