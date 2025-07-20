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
                    VStack(spacing: 24) {
                        // Video Selection
                        videoSelectionSection
                        
                        // Category Selection
                        categorySection
                        
                        // Title and Note
                        inputSection
                        
                        // Notice
                        noticeSection
                        
                        Color.clear.frame(height: 100)
                    }
                    .padding(.top)
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
            .onChange(of: viewModel.lastUploadedMemory) { memory in
                if memory != nil {
                    showDoneView = true
                }
            }
            .navigationDestination(isPresented: $showDoneView) {
                iOSAddMemoryDoneView(viewModel: viewModel, diContainer: diContainer)
            }
            .onChange(of: viewModel.selectedVideoItem) { newItem in
                viewModel.handleVideoSelection(item: newItem)
            }
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
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [8]))
                                    .foregroundColor(.white.opacity(0.3))
                            )
                    )
                }
            }
        }
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Category")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
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
    private var inputSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Title
            VStack(alignment: .leading, spacing: 8) {
                Text("Title")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                
                TextField("Enter title", text: $viewModel.title)
                    .textFieldStyle(iOSTextFieldStyle())
            }
            
            // Note
            VStack(alignment: .leading, spacing: 8) {
                Text("Note")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                
                TextEditor(text: $viewModel.note)
                    .frame(minHeight: 100)
                    .padding(12)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(8)
                    .foregroundColor(.white)
                    .scrollContentBackground(.hidden)
            }
        }
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private var noticeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 16))
                Text("Notice")
                    .font(.system(size: 16, weight: .medium))
            }
            .foregroundColor(.white.opacity(0.8))
            
            Text("• Only spatial videos are supported")
            Text("• Maximum file size: 2GB")
            Text("• Supported formats: MOV, MP4")
        }
        .font(.system(size: 14))
        .foregroundColor(.white.opacity(0.6))
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(8)
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private var uploadButton: some View {
        Button(action: {
            Task {
                guard let userId = appState.userId else { return }
                await viewModel.saveMemory(note: viewModel.note, title: viewModel.title, userId: userId)
            }
        }) {
            HStack {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 20))
                Text("Upload")
                    .font(.system(size: 17, weight: .semibold))
            }
            .foregroundColor(.NebulaBlack)
            .padding(.horizontal, 32)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: viewModel.isUploadEnabled ? [Color.purple, Color.pink] : [Color.gray],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(25)
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
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(category.iconName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                Text(category.rawValue)
                    .font(.system(size: 14))
            }
            .foregroundColor(isSelected ? .NebulaBlack : .white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? AnyShapeStyle(LinearGradient.GradientMain) : AnyShapeStyle(Color.white.opacity(0.1)))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.clear : Color.white.opacity(0.2), lineWidth: 1)
            )
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