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
        ScrollView {
            VStack(spacing: 24) {
                // Profile Image Section
                VStack(spacing: 16) {
                    ZStack {
                        if let profileImageUrl = settingViewModel.profile?.profileImageURL {
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
                                        .foregroundColor(.NebulaBlack)
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
                    
                    // Nickname Section
                    if isEditMode {
                        TextField("Nickname", text: $tempNickname)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(maxWidth: 250)
                    } else {
                        Text(settingViewModel.profile?.name ?? "Unknown")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                }
                .padding(.top, 20)
                
                // Edit/Save Button
                Button(action: {
                    if isEditMode {
                        // Save changes
                        Task {
                            await settingViewModel.updateProfileIfNeeded(newName: tempNickname, selectedImage: nil)
                            isEditMode = false
                        }
                    } else {
                        // Enter edit mode
                        tempNickname = settingViewModel.profile?.name ?? ""
                        isEditMode = true
                    }
                }) {
                    Text(isEditMode ? "Done" : "Edit")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 100, height: 44)
                        .background(LinearGradient.GradientMain)
                        .cornerRadius(22)
                }
                .padding(.top, 10)
            }
            .padding()
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showProfileSelector) {
            iOSProfileSelectorView(settingViewModel: settingViewModel)
        }
        .task {
            await settingViewModel.fetchProfile()
        }
    }
}

struct iOSProfileSelectorView: View {
    @ObservedObject var settingViewModel: SettingViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedItem: PhotosPickerItem?
    
    private let predefinedImages = (1...8).map { "profile\($0)" }
    
    @ViewBuilder
    private var photoPicker: some View {
        PhotosPicker(selection: $selectedItem, matching: .images) {
            VStack {
                Image(systemName: "photo.badge.plus")
                    .font(.system(size: 40))
                    .foregroundColor(.gray)
                Text("Choose from Library")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 120)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
        .onChange(of: selectedItem) { _, newItem in
            Task {
                if let item = newItem,
                   let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    await settingViewModel.updateProfileIfNeeded(newName: nil, selectedImage: .custom(image))
                    dismiss()
                }
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Custom Photo Picker
                    photoPicker
                    
                    // Predefined Images Grid
                    Text("Or choose a preset")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                        ForEach(predefinedImages, id: \.self) { imageName in
                            Button(action: {
                                Task {
                                    if let predefinedImage = PredefinedProfileImage(rawValue: imageName) {
                                    await settingViewModel.updateProfileIfNeeded(newName: nil, selectedImage: .predefined(predefinedImage))
                                }
                                    dismiss()
                                }
                            }) {
                                ZStack {
                                    Image(imageName)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 70, height: 70)
                                        .clipShape(Circle())
                                    
                                    if false { // TODO: Fix selected image check
                                        Circle()
                                            .stroke(LinearGradient.GradientMain, lineWidth: 3)
                                            .frame(width: 75, height: 75)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Select Profile Photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}