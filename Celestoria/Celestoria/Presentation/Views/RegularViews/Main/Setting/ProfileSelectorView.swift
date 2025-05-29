//
//  ProfileSelectorView.swift
//  Celestoria
//
//  Created by Park Seyoung on 5/25/25.
//

import SwiftUI
import PhotosUI

// MARK: - Profile Selector View
struct ProfileSelectorView: View {
    let viewModel: SettingViewModel
    @Binding var showProfileSelector: Bool
    @State private var selectedItem: PhotosPickerItem?
    @State private var tempSelectedImage: ProfileImageSelection?
    
    // 미리 정의된 프로필 이미지들
    private let predefinedImages = PredefinedProfileImage.allCases
    
    init(viewModel: SettingViewModel, showProfileSelector: Binding<Bool>) {
        self.viewModel = viewModel
        self._showProfileSelector = showProfileSelector
    }
    
    var body: some View {
        ZStack {
            VStack() {
                // Header
                HStack {
                    Text("Change Profile")
                        .font(.system(size: 29, weight: .bold))
                        .foregroundColor(.NebulaWhite)
                    
                    Spacer()
                    
                    Button(action: {
                        showProfileSelector = false
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
                
                // Grid of profile images
                ScrollView {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 20), count: 3), spacing: 24) {
                        
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
                        .buttonStyle(MainButtonStyle())
                        .onChange(of: selectedItem) { newItem in
                            Task {
                                if let data = try? await newItem?.loadTransferable(type: Data.self),
                                   let image = UIImage(data: data) {
                                    await MainActor.run {
                                        tempSelectedImage = .custom(image)
                                    }
                                }
                            }
                        }
                        
                        // Predefined profile images
                        ForEach(predefinedImages, id: \.self) { predefinedImage in
                            Button(action: {
                                tempSelectedImage = .predefined(predefinedImage)
                            }) {
                                ProfileCell(
                                    image: predefinedImage.rawValue,
                                    isSelected: isImageSelected(predefinedImage)
                                )
                            }
                            .buttonStyle(MainButtonStyle())
                        }
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 160)
                    .padding(.horizontal, 8)
                }
                .padding(.horizontal, 56)
                .padding(.top, 56)
            }
            
            VStack {
                Spacer()
                
                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(stops: [
                                .init(color: Color.black.opacity(0.0), location: 0.0),
                                .init(color: Color.black.opacity(0.7), location: 1.0)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: 100)
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 0)
                    .allowsHitTesting(false)
            }
            
            VStack {
                Spacer()
                // Save button
                Button(action: {
                    if let tempImage = tempSelectedImage {
                        viewModel.selectedImage = tempImage
                        viewModel.updateUploadEnabled()
                    }
                    showProfileSelector = false
                }) {
                    Text("SAVE")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(hasChanges ? .black : .black.opacity(0.3))
                        .frame(maxWidth: .infinity)
                        .frame(height: 76)
                        .background(
                            hasChanges ?
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
                .disabled(!hasChanges)
                .padding(.bottom, 60)
                .padding(.horizontal, 40)
                .buttonStyle(MainButtonStyle())
                .frame(maxWidth: .infinity)
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .frame(width: 778, height: 820)
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
        .overlay(
            RoundedRectangle(cornerRadius: 46)
                .inset(by: 1.5)
                .stroke(.white, lineWidth: 3)
        )
        .onAppear {
            // 현재 선택된 이미지를 tempSelectedImage로 설정
            tempSelectedImage = viewModel.selectedImage
        }
        .onChange(of: selectedItem) { newItem in
            Task {
                guard let item = newItem else {
                    print("❌ selectedItem is nil")
                    return
                }
                
                do {
                    if let data = try await item.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        await MainActor.run {
                            print("✅ 이미지 불러오기 성공")
                            tempSelectedImage = .custom(image)
                        }
                    } else {
                        print("❌ loadTransferable는 성공했지만 UIImage 변환 실패")
                    }
                } catch {
                    print("❌ 이미지 로딩 실패:", error.localizedDescription)
                }
            }
        }
    }
    
    // 선택된 이미지인지 확인하는 헬퍼 함수
    private func isImageSelected(_ predefinedImage: PredefinedProfileImage) -> Bool {
        if let tempImage = tempSelectedImage {
            switch tempImage {
            case .predefined(let selected):
                return selected == predefinedImage
            case .custom(_):
                return false
            }
        }
        return false
    }
    
    // 변경사항이 있는지 확인하는 computed property
    private var hasChanges: Bool {
        guard let tempImage = tempSelectedImage else { return false }
        let current = viewModel.selectedImage ?? .predefined(.profile_gray)
        return hasChanges(currentImage: current, tempImage: tempImage)
    }
    
    private func hasChanges(currentImage: ProfileImageSelection, tempImage: ProfileImageSelection) -> Bool {
        switch (currentImage, tempImage) {
        case (.predefined(let original), .predefined(let temp)):
            return original != temp
            
        case (.custom(_), .custom(_)):
            return true // 커스텀 이미지는 항상 변경으로 간주
            
        case (.custom(_), .predefined(_)), (.predefined(_), .custom(_)):
            return true
        }
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
                    .frame(width: 206, height: 206)
                    .clipShape(Circle())
            } else {
                // Fallback image
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 206, height: 206)
            }
            
            // Selection overlay
            if isSelected {
                Circle()
                    .stroke(
                        LinearGradient(
                            stops: [
                                Gradient.Stop(color: Color(red: 0.65, green: 0.91, blue: 1), location: 0.00),
                                Gradient.Stop(color: Color(red: 0.71, green: 0.79, blue: 1), location: 1.00),
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 3
                    )
                    .frame(width: 206, height: 206)
                
                // Check mark
                Image("Check-Circle")
                    .resizable()
                    .frame(width: 30, height: 30)
                    .offset(x: -8, y: 8)
            }
        }
        .frame(width: 210, height: 210)
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
                        .frame(width: 206, height: 206)
                    
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 150, height: 150)
                        .clipShape(Circle())
                    
                    Circle()
                        .fill(.black.opacity(0.2))
                        .frame(width: 206, height: 206)
                    
                    Image(systemName: "plus")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.NebulaWhite.opacity(0.5))
                    
                    if isSelected {
                        Circle()
                            .stroke(
                                LinearGradient(
                                    stops: [
                                        Gradient.Stop(color: Color(red: 0.65, green: 0.91, blue: 1), location: 0.00),
                                        Gradient.Stop(color: Color(red: 0.71, green: 0.79, blue: 1), location: 1.00),
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 3
                            )
                            .frame(width: 206, height: 206)
                        
                        // Check mark
                        Image("Check-Circle")
                            .resizable()
                            .frame(width: 30, height: 30)
                            .offset(x: 80, y: -80)
                    }
                    
                } else {
                    Circle()
                        .stroke(Color(hex: "424242"), lineWidth: 3)
                        .frame(width: 206, height: 206)
                        .background(.clear)
                    
                    Image(systemName: "plus")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.NebulaWhite.opacity(0.5))
                }
            }
        }
        .buttonStyle(MainButtonStyle())
    }
}
