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
    @EnvironmentObject var mainViewModel : MainViewModel
    @EnvironmentObject private var appModel: AppModel
    
    @State private var isHovered: Bool = false
    
    var body: some View {
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
                
                // Right Viewr
                RightView()
                    .frame(width: geometry.size.width / 2, height: geometry.size.height)
            }
            .background(
                Group {
                    if let thumbnail = viewModel.thumbnailImage {
                        Image(uiImage: thumbnail)
                            .resizable()
                            .scaledToFill()
                            .clipped()
                    } else {
                        Color.NebulaBlack
                    }
                }
            )
            .overlay(
                Group {
                    if let popupData = viewModel.popupData {
                        ZStack {
                            Color.black.opacity(0.6) // 어두운 배경
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
                            .frame(width: 644, height: 324)
                            .cornerRadius(20)
                        }
                    }
                }
            )
        }
        .onDisappear {
            viewModel.handleViewDisappearance()
            appModel.showAddMemoryView = false
        }
        // Alert for Success
        .alert(isPresented: $viewModel.showSuccessAlert) {
            Alert(
                title: Text("Success"),
                message: Text("Memory saved successfully!"),
                dismissButton: .default(Text("OK"))
            )
        }
        // Handle Error Messages
        .onChange(of: viewModel.errorMessage) {
            guard let message = viewModel.errorMessage else { return }
            print("Error: \(message)")
        }
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
                    appModel.showAddMemoryView = false
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
                                .foregroundColor(.white)
                                .font(.system(size: 17))
                                .padding(.top, 4)
                        }
                    }
                    .frame(width: 260, height: 132)
                    .cornerRadius(20)
                    .buttonStyle(PlainButtonStyle())
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
                        .buttonStyle(UploadButtonStyle())
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
                
                UploadButton(
                    action: {
                        guard let userId = appModel.userId else { return }
                        Task {
                            do {
                                await viewModel.saveMemory(
                                    note: viewModel.note,
                                    title: viewModel.title,
                                    userId: userId
                                )
                                
                                await mainViewModel.fetchMemories(for: userId)
                                
                                dismissWindow(id: "Add-Memory")
                            } catch {
                                os.Logger.error("Failed to save memory: \(error)")
                            }
                        }
                    },
                    isEnabled: viewModel.isUploadEnabled
                )
                .disabled(!viewModel.isUploadEnabled)
                
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
        ZStack {
            RoundedRectangle(cornerRadius: 36)
                .stroke(Color(hex: "9D9D9D"), lineWidth: 1)
                .frame(width: 560, height: 288)
            
            VStack() {
                // Title Input
                TextField("Write the title", text: $viewModel.title)
                    .font(.system(size: 19, weight: .bold))
                    .foregroundColor(.NebulaWhite)
                    .padding(.top, 28)
                    .frame(width: 504, height: 64, alignment: .bottomLeading)
                
                Divider()
                    .background(Color(hex: "9D9D9D"))
                    .frame(width: 560, height: 1)
                
                // Note Input
                TextField("Write the note", text: $viewModel.note, axis: .vertical)
                    .onChange(of: viewModel.note) { newValue in
                        if newValue.count > 500 {
                            viewModel.note = String(newValue.prefix(500))
                        }
                    }
                    .font(.system(size: 19, weight: .bold))
                    .foregroundColor(.NebulaWhite)
                    .padding(.top, 12)
                    .frame(width: 504, height: 228, alignment: .topLeading)
                
                // Character Count
                Text("\(viewModel.note.count) / 500")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(Color(hex: "9D9D9D"))
                    .frame(width: 560, alignment: .trailing)
                    .padding(.top, 4)
            }
        }
        .frame(width: 560, height: 320, alignment: .center)
    }
}

// MARK: - Upload Button
private struct UploadButton: View {
    let action: () -> Void
    let isEnabled: Bool
    
    var body: some View {
        Button(action: action) {
            Text("Upload")
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(isEnabled ? .NebulaWhite : .NebulaBlack)
                .frame(width: 380, height: 64)
                .background(isEnabled ?
                            AnyShapeStyle(LinearGradient.GradientSub) :
                                AnyShapeStyle(Color(hex:"1F1F29"))).cornerRadius(16)
        }
        .buttonStyle(UploadButtonStyle())
        .padding(.bottom, 60)
    }
}


struct UploadButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

