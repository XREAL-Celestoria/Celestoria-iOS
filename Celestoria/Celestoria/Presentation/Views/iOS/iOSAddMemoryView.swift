//
//  iOSAddMemoryView.swift
//  Celestoria
//
//  Created by Minjun Kim on 7/20/25.
//

import SwiftUI
import PhotosUI
import AVFoundation

struct iOSAddMemoryView: View {
    @StateObject private var viewModel: AddMemoryMainViewModel
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var showDoneView = false
    let diContainer: DIContainer
    
    init(diContainer: DIContainer) {
        self.diContainer = diContainer
        _viewModel = StateObject(wrappedValue: diContainer.makeAddMemoryMainViewModel())
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.NebulaBlack
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Thumbnail
                        thumbnailSection
                        
                        // Category Selection
                        categorySection
                        
                        // Text
                        textSection
                        
                        // Notice
                        noticeSection
                        
                        Color.clear.frame(height: 100)
                    }
                    .padding(.top, 20)
                }
                
                // Upload Button
                VStack {
                    Spacer()
                    uploadButton
                        .padding(.bottom, 30)
                }
                
                // Overlay
                if viewModel.isThumbnailGenerating || viewModel.isUploading || viewModel.popupData != nil {
                    overlayView
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("Add Memory Star")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                    }
                }
            }
            .onChange(of: viewModel.lastUploadedMemory) { _, memory in
                if memory != nil {
                    showDoneView = true
                }
            }
            .navigationDestination(isPresented: $showDoneView) {
                iOSAddMemoryDoneView(viewModel: viewModel, diContainer: diContainer)
            }
            .onChange(of: viewModel.selectedVideoItem) { _, newItem in
                viewModel.handleVideoSelection(item: newItem)
            }
        }
    }
    
    @ViewBuilder
    private var thumbnailSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Thumbnail")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal)
            
            videoSelectionSection
        }
    }
    
    @ViewBuilder
    private var videoSelectionSection: some View {
        VStack(spacing: 16) {
            if let thumbnail = viewModel.thumbnailImage {
                Image(uiImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 200)
                    .clipped()
                    .cornerRadius(12)
                    .overlay(
                        PhotosPicker(selection: $viewModel.selectedVideoItem, matching: .videos) {
                            Color.clear
                        }
                    )
            } else {
                PhotosPicker(selection: $viewModel.selectedVideoItem, matching: .videos) {
                    VStack(spacing: 12) {
                        Image(systemName: "video.badge.plus")
                            .font(.system(size: 40))
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text("Select your spatial video")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [10, 5]))
                                    .foregroundColor(.white.opacity(0.4))
                            )
                    )
                }
            }
        }
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Category")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
            
            HStack(spacing: 12) {
                ForEach(Category.allCases, id: \.self) { category in
                    iOSCategoryButton(
                        category: category,
                        isSelected: viewModel.selectedCategory == category,
                        action: {
                            viewModel.selectedCategory = category
                        }
                    )
                }
            }
        }
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private var textSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Text")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal)
            
            ZStack(alignment: .bottomTrailing) {
                VStack(spacing: 0) {
                    // Title
                    TextField("Write the title", text: $viewModel.title)
                        .textFieldStyle(PlainTextFieldStyle())
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                    
                    Divider()
                        .background(Color.white.opacity(0.3))
                        .padding(.horizontal, 20)
                    
                    // Note with character limit
                    ZStack(alignment: .topLeading) {
                        if viewModel.note.isEmpty {
                            Text("Write the note")
                                .font(.system(size: 16))
                                .foregroundColor(.white.opacity(0.5))
                                .padding(.horizontal, 20)
                                .padding(.top, 16)
                                .allowsHitTesting(false)
                        }
                        
                        TextEditor(text: $viewModel.note)
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.top, 12)
                            .padding(.bottom, 40) // Space for character counter
                            .frame(minHeight: 180)
                            .scrollContentBackground(.hidden)
                            .background(Color.clear)
                            .onChange(of: viewModel.note) { _, newValue in
                                if newValue.count > 500 {
                                    viewModel.note = String(newValue.prefix(500))
                                }
                            }
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(viewModel.note.count >= 500 ? Color.red.opacity(0.8) : Color.white.opacity(0.3), lineWidth: 1)
                )
                
                // Character count inside the box
                Text("\(viewModel.note.count) / 500")
                    .font(.system(size: 14))
                    .foregroundColor(viewModel.note.count >= 500 ? .red : .white.opacity(0.6))
                    .padding(.trailing, 20)
                    .padding(.bottom, 16)
            }
            .padding(.horizontal)
            
            if viewModel.note.count >= 500 {
                Text("The content exceeds the character limit.")
                    .font(.system(size: 13))
                    .foregroundColor(.red)
                    .padding(.horizontal, 20)
                    .padding(.top, -8)
            }
        }
    }
    
    @ViewBuilder
    private var noticeSection: some View {
        VStack(alignment: .center, spacing: 16) {
            HStack {
                Image(systemName: "info.circle")
                    .font(.system(size: 18))
                Text("Notice")
                    .font(.system(size: 18, weight: .semibold))
            }
            .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("• Only spatial videos are supported")
                Text("• Maximum file size: 2GB")
                Text("• Supported formats: MOV, MP4")
            }
            .font(.system(size: 14))
            .foregroundColor(.white.opacity(0.7))
        }
        .padding(.horizontal)
        .padding(.top, 20)
    }
    
    @ViewBuilder
    private var uploadButton: some View {
        Button(action: {
            Task {
                guard let userId = appState.userId else { return }
                await viewModel.saveMemory(note: viewModel.note, title: viewModel.title, userId: userId)
            }
        }) {
            HStack(spacing: 8) {
                Image(systemName: "arrow.up")
                    .font(.system(size: 18, weight: .semibold))
                Text("Upload")
                    .font(.system(size: 17, weight: .semibold))
            }
            .foregroundColor(viewModel.isUploadEnabled ? .white : .white.opacity(0.6))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        viewModel.isUploadEnabled ?
                        LinearGradient(
                            colors: [Color(hex: "#A68CFF"), Color(hex: "#FF6B99")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) :
                        LinearGradient(
                            colors: [Color.gray.opacity(0.4)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
            .padding(.horizontal, 20)
        }
        .disabled(!viewModel.isUploadEnabled)
    }
    
    @ViewBuilder
    private var overlayView: some View {
        Color.black.opacity(0.7)
            .ignoresSafeArea()
        
        if viewModel.isUploading {
            iOSUploadProgressView(
                progress: viewModel.uploadProgress,
                fileSize: viewModel.uploadingFileSize
            )
        } else if let popupData = viewModel.popupData {
            iOSPopupView(popupData: popupData)
        } else if viewModel.isThumbnailGenerating {
            ProgressView("Loading...")
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .foregroundColor(.white)
                .padding()
                .background(Color.black.opacity(0.8))
                .cornerRadius(12)
        }
    }
}

struct iOSCategoryButton: View {
    let category: Category
    let isSelected: Bool
    let action: () -> Void
    
    var iconName: String {
        switch category {
        case .PET:
            return "pawprint"
        case .ENTERTAINMENT:
            return "bolt"
        case .TRAVEL:
            return "airplane"
        case .FAMILY:
            return "heart"
        }
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                // Circular button with icon
                ZStack {
                    Circle()
                        .fill(
                            isSelected ? 
                            LinearGradient(
                                colors: [Color(hex: "#A68CFF"), Color(hex: "#7B61FF")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ) : 
                            LinearGradient(
                                colors: [Color.clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            Circle()
                                .stroke(
                                    isSelected ? Color.clear : Color.white.opacity(0.4),
                                    lineWidth: 1.5
                                )
                        )
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: iconName)
                        .font(.system(size: 24))
                        .foregroundColor(isSelected ? .white : .white.opacity(0.8))
                }
                
                // Category name below
                Text(category.displayName.capitalized)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(isSelected ? .white : .white.opacity(0.8))
            }
            .frame(maxWidth: .infinity)
        }
    }
}

struct iOSTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(12)
            .background(Color.white.opacity(0.1))
            .cornerRadius(8)
            .foregroundColor(.white)
    }
}

struct iOSUploadProgressView: View {
    let progress: Double
    let fileSize: String
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Uploading Memory")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
            
            Text("Uploading \(fileSize) video file...")
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.8))
            
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(1.5)
                .padding(.top, 10)
        }
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.NebulaBlack)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

struct iOSPopupView: View {
    let popupData: PopupData
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 24) {
            Text(popupData.title)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            if !popupData.notes.isEmpty {
                Text(popupData.notes)
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
            
            HStack(spacing: 16) {
                if let leadingText = popupData.leadingButtonText,
                   let leadingAction = popupData.leadingButtonAction {
                    Button(action: {
                        leadingAction()
                        if popupData.dismissOnAction {
                            dismiss()
                        }
                    }) {
                        Text(leadingText)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
                
                Button(action: {
                    popupData.trailingButtonAction()
                    if popupData.dismissOnAction {
                        dismiss()
                    }
                }) {
                    Text(popupData.trailingButtonText)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.NebulaBlack)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(LinearGradient.GradientMain)
                        .cornerRadius(8)
                }
            }
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.NebulaBlack)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
        .padding(.horizontal, 40)
    }
}

// PopupData extension for iOS
extension PopupData {
    var dismissOnAction: Bool {
        return true
    }
}