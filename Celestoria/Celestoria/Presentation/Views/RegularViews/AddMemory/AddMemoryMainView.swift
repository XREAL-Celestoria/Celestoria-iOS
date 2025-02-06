//
//  AddMemoryMainView.swift
//  Celestoria
//
//  Created by Park Seyoung on 1/22/25.
//

import SwiftUI
import PhotosUI
import AVFoundation
import os

struct AddMemoryMainView: View {
    @EnvironmentObject var viewModel: AddMemoryMainViewModel
    @EnvironmentObject var mainViewModel: MainViewModel
    @EnvironmentObject private var appModel: AppModel
    
    @State private var isHovered: Bool = false
    
    var body: some View {
        ZStack {
            // 기존 UI
            GeometryReader { geometry in
                HStack(spacing: 0) {
                    // Left View
                    LeftView(isHovered: $isHovered)
                        .frame(width: geometry.size.width / 2, height: geometry.size.height)
                        .onHover { isHovering in
                            withAnimation {
                                isHovered = isHovering
                            }
                        }
                        .contentShape(Rectangle())
                    
                    // Right View
                    RightView()
                        .frame(width: geometry.size.width / 2, height: geometry.size.height )
                }
                .background(
                    Group {
                        if let thumbnail = viewModel.thumbnailImage {
                            Image(uiImage: thumbnail)
                                .resizable()
                                .scaledToFill()
                                .clipped()
                                .overlay(Color.NebulaBlack.opacity(0.6))
                        } else {
                            Color.NebulaBlack
                        }
                    }
                )
                .overlay(
                    Group {
                        if let popupData = viewModel.popupData {
                            ZStack {
                                Color.black.opacity(0.6)
                                    .ignoresSafeArea()
                                PopupView(
                                    title: popupData.title,
                                    notes: popupData.notes,
                                    leadingButtonText: popupData.leadingButtonText,
                                    trailingButtonText: popupData.trailingButtonText,
                                    circularAction: popupData.circularAction,
                                    leadingButtonAction: popupData.leadingButtonAction,
                                    trailingButtonAction: popupData.trailingButtonAction,
                                    buttonImageString: popupData.buttonImageString
                                )
                                .frame(width: 656, height: 332, alignment: .center)
                            }
                        }
                    }
                )
            }
            .onDisappear {
                viewModel.handleViewDisappearance()
                appModel.showAddMemoryView = false
            }
            .onChange(of: viewModel.errorMessage) { _ in
                if let message = viewModel.errorMessage {
                    print("Error: \(message)")
                }
            }
            
            if viewModel.isThumbnailGenerating || viewModel.isUploading {
                ZStack {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                    
                    VStack {
                        ProgressView("Loading...")
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .foregroundColor(.white)
                            .padding()
                    }
                }
                .transition(.opacity)
            }
            
            // Upload progress overlay
            if viewModel.isUploading {
                Color.black.opacity(0.7)
                    .edgesIgnoringSafeArea(.all)
                
                UploadProgressPopup(
                    fileSize: viewModel.uploadingFileSize,
                    progress: viewModel.uploadProgress
                )
            }
            
            // Existing popup
            if let popupData = viewModel.popupData {
                Color.black.opacity(0.7)
                    .edgesIgnoringSafeArea(.all)
                
                PopupView(
                    title: popupData.title,
                    notes: popupData.notes,
                    leadingButtonText: popupData.leadingButtonText,
                    trailingButtonText: popupData.trailingButtonText,
                    circularAction: popupData.circularAction,
                    leadingButtonAction: popupData.leadingButtonAction,
                    trailingButtonAction: popupData.trailingButtonAction,
                    buttonImageString: popupData.buttonImageString
                )
            }
        }
        .animation(.easeInOut, value: viewModel.isThumbnailGenerating)
    }
}


// MARK: - Left View
private struct LeftView: View {
    @EnvironmentObject var viewModel: AddMemoryMainViewModel
    @Environment(\.dismissWindow) private var dismissWindow
    @EnvironmentObject private var appModel: AppModel
    
    @Binding var isHovered: Bool
    
    var body: some View {
        VStack {
            // 네비게이션 바
            NavigationBar(
                title: "Add Memory Star",
                action: {
                    dismissWindow(id: "Add-Memory")
                },
                buttonImageString: "xmark"
            )
            .padding(.horizontal, 28)
            .padding(.top, 28)
            
            Spacer()
            
            // 비디오 선택 UI
            ZStack {
                if viewModel.thumbnailImage == nil || isHovered {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.NebulaBlack.opacity(0.5))
                        .stroke(Color(hex: "9D9D9D"), lineWidth: 2)
                        .frame(width: 260, height: 132)
                    
                    PhotosPicker(selection: $viewModel.selectedVideoItem, matching: .spatialMedia) {
                        VStack {
                            Image("AddMemoryVideoIcon")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)
                            Text("Select your spatial video")
                                .foregroundColor(Color.NebulaWhite)
                                .font(.system(size: 17))
                                .padding(.top, 4)
                        }
                    }
                    .frame(width: 260, height: 132)
                    .cornerRadius(20)
                    .buttonStyle(MainButtonStyle())
                    .disabled(viewModel.isPickerBlocked)
                    .onChange(of: viewModel.selectedVideoItem) { newItem in
                        viewModel.handleVideoSelection(item: newItem)
                    }
                    
                    // 포토피커 활성화 버튼
                    if viewModel.isPickerBlocked {
                        Button(action: {
                            viewModel.showPhotosPickerPopup {
                                dismissWindow(id: "Add-Memory")
                            }
                        }) {
                            Color.NebulaBlack.opacity(0.5)
                        }
                        .frame(width: 260, height: 132)
                        .cornerRadius(20)
                        .buttonStyle(MainButtonStyle())
                    }
                }
            }
            .frame(width: 260, height: 132)
            
            Spacer()
        }
    }
}

// MARK: - Right View
private struct RightView: View {
    @EnvironmentObject var viewModel: AddMemoryMainViewModel
    @EnvironmentObject var mainViewModel : MainViewModel
    @EnvironmentObject private var appModel: AppModel
    @Environment(\.dismissWindow) private var dismissWindow
    
    var body: some View {
        ZStack {
            VisualEffectBlur(style: .systemMaterial)
                .edgesIgnoringSafeArea(.all)
        
            Rectangle()
                .fill(Color.clear)
                .overlay(
                    Color.NebulaBlack.opacity(0.3)
                        .shadow(.inner(color: Color.NebulaWhite.opacity(0.8), radius: 24))
                )
                .edgesIgnoringSafeArea(.all)
            
            VStack() {
                // Category Section
                Text("Category")
                    .foregroundColor(.NebulaWhite)
                    .font(.system(size: 22, weight: .bold))
                    .padding(.top, 64)
                
                Spacer()
                
                CategoryButtons()
                
                Spacer()
                
                NoteInputSection()
                
                Spacer()
                
                MainButton(
                    title: "Upload",
                    action: {
                        guard let userId = appModel.userId else { return }
                        Task {
                            do {
                                os.Logger.info("executing saveMemory")
                                await viewModel.saveMemory(
                                    note: viewModel.note,
                                    title: viewModel.title,
                                    userId: userId
                                )

                                appModel.addMemoryScreen = .done
                            } catch {
                                os.Logger.error("Failed to save memory: \(error)")
                            }
                        }
                    },
                    isEnabled: viewModel.isUploadEnabled && !viewModel.isUploading
                )
                .disabled(!viewModel.isUploadEnabled || viewModel.isUploading)
                .padding(.bottom, 60)

                
                Spacer()
            }
        }
    }
}

// MARK: - Category Buttons
private struct CategoryButtons: View {
    @EnvironmentObject var viewModel: AddMemoryMainViewModel
    
    var body: some View {
        HStack(spacing: 60) {
            CategoryButton(
                category: Category.PET,
                isSelected: viewModel.selectedCategory == Category.PET,
                action: {
                    viewModel.toggleCategory(Category.PET)
                }
            )
            CategoryButton(
                category: Category.ENTERTAINMENT,
                isSelected: viewModel.selectedCategory == Category.ENTERTAINMENT,
                action: {
                    viewModel.toggleCategory(Category.ENTERTAINMENT)
                }
            )
            CategoryButton(
                category: Category.TRAVEL,
                isSelected: viewModel.selectedCategory == Category.TRAVEL,
                action: {
                    viewModel.toggleCategory(Category.TRAVEL)
                }
            )
            CategoryButton(
                category: Category.FAMILY,
                isSelected: viewModel.selectedCategory == Category.FAMILY,
                action: {
                    viewModel.toggleCategory(Category.FAMILY)
                }
            )
        }
        .frame(width: 140, height: 75, alignment: .center)
        .padding()
    }
}

// MARK: - Note Input Section
private struct NoteInputSection: View {
    @EnvironmentObject var viewModel: AddMemoryMainViewModel
    
    var body: some View {
        
        let isTitleEmpty = viewModel.title.trimmingCharacters(in: .whitespaces).isEmpty
        let isNoteEmpty = viewModel.note.isEmpty
        let isBothEmpty = isTitleEmpty && isNoteEmpty
        let isTitleValid = !isTitleEmpty && viewModel.title.trimmingCharacters(in: .whitespaces).count < 50
        let isNoteValid = !isNoteEmpty && viewModel.note.count < 500
        
        let isExceedingLimit = viewModel.title.count >= 50 || viewModel.note.count >= 500
        
        let overallColor: AnyShapeStyle = {
            if isBothEmpty {
                return AnyShapeStyle(Color(hex:"9D9D9D"))
            } else if !isTitleValid || !isNoteValid {
                return AnyShapeStyle(Color.NebulaRed)
            } else {
                return AnyShapeStyle(LinearGradient.GradientStroke)
            }
        }()
        
        ZStack {
            RoundedRectangle(cornerRadius: 36)
                .stroke(overallColor, lineWidth: 1)
                .frame(width: 560, height: 288)
            
            VStack() {
                // Title Input
                TextField("Write the title", text: $viewModel.title)
                    .onChange(of: viewModel.title) { newValue in
                        if newValue.count >= 50 {
                            viewModel.title = String(newValue.prefix(50))
                        }
                    }
                    .font(.system(size: 19, weight: .bold))
                    .foregroundColor(.NebulaWhite)
                    .padding(.top, 28)
                    .frame(width: 504, height: 64, alignment: .bottomLeading)
                
                Divider()
                    .background(overallColor)
                    .frame(width: 560, height: 1)
                
                // Note Input
                TextField("Write the note", text: $viewModel.note, axis: .vertical)
                    .onChange(of: viewModel.note) { newValue in
                        if newValue.count >= 500 {
                            viewModel.note = String(newValue.prefix(500))
                        }
                    }
                    .font(.system(size: 19, weight: .bold))
                    .foregroundColor(.NebulaWhite)
                    .padding(.top, 12)
                    .frame(width: 504, height: 228, alignment: .topLeading)
                
                HStack {
                    Text("The content exceeds the character limit.")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.NebulaRed)
                        .padding(.leading, 4)
                        .opacity(isExceedingLimit ? 1 : 0)
                
                    Spacer()
                                 
                    Text("\(viewModel.note.count) / 500")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(overallColor)
                        .padding(.trailing, 4)
                }
                .frame(width: 560, alignment: .bottom)
                .padding(.top, 4)
            }
        }
        .frame(width: 560, height: 320, alignment: .center)
    }
}

