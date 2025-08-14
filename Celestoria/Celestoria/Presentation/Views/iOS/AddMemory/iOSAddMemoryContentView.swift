
//
//  iOSAddMemoryContentView.swift
//  Celestoria
//
//  Created by Seyoung Park on 8/3/25.
//

import SwiftUI
import PhotosUI

struct iOSAddMemoryContentView: View {
    @StateObject private var viewModel: AddMemoryMainViewModel
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var showDoneView = false
    @State private var showFileSizePopup = false
    @State private var showUploadProgress = false
    @State private var showLoadingPopup = false
    @State private var isUploadCompleted = false // 업로드 완료 상태
    let diContainer: DIContainer
    let onShowMemoryDetail: (Memory) -> Void
    
    init(diContainer: DIContainer, onShowMemoryDetail: @escaping (Memory) -> Void) {
        self.diContainer = diContainer
        self.onShowMemoryDetail = onShowMemoryDetail
        _viewModel = StateObject(wrappedValue: diContainer.makeAddMemoryMainViewModel())
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Colors.NebulaBlack
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    if !showDoneView {
                        iOSNavigationView(title: "Add Memory Star", onBack: {dismiss()})
                    } else {
                        HStack {
                            Spacer()
                            
                            Button(action: {
                                // 메인 뷰로 돌아가기 (리프레시 최소화)
                                dismiss()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    appState.refreshMainView = true
                                }
                            }) {
                                Image("closeWhiteIcon")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 24, height: 24)
                            }
                            .padding(.trailing, 20)
                            .padding(.top, 50)
                            .zIndex(1) // Done 뷰 위에 표시되도록 z-index 설정
                        }
                        .background(
                            Colors.BackgroundBlack
                        )
                    }
                    
                    
                    
                    if showDoneView {
                        // 업로드 완료 후 Done 뷰
                        iOSAddMemoryDoneView(
                            viewModel: viewModel,
                            diContainer: diContainer,
                            onShowMemoryDetail: onShowMemoryDetail,
                            onComplete: {
                                dismiss()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    // 메인 뷰 새로고침 (지연시간 증가)
                                    appState.refreshMainView = true
                                }
                            }
                        )
                        .ignoresSafeArea()
                    } else if viewModel.thumbnailImage == nil {
                        // 초기 상태: 비디오 선택 화면
                        VideoSelectionView(viewModel: viewModel)
                    } else {
                        // 썸네일이 있을 때: 편집 화면
                        MemoryEditView(
                            viewModel: viewModel,
                            appState: appState,
                            showDoneView: $showDoneView
                        )
                    }
                }
            }
        }
        .overlay(
            Group {
                if showLoadingPopup || showUploadProgress {
                    loadingOverlay
                        .allowsHitTesting(false) // 터치 이벤트 통과 (업로드 중에도 취소 가능)
                }
                
                if showFileSizePopup {
                    fileSizePopup
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.8).combined(with: .opacity),
                            removal: .scale(scale: 0.9).combined(with: .opacity)
                        ))
                }
            }
        )
        
        .animation(.easeInOut(duration: 0.3), value: viewModel.thumbnailImage != nil)
        .onChange(of: viewModel.selectedVideoItem) { _, newItem in
            viewModel.handleVideoSelection(item: newItem)
        }
        .onChange(of: viewModel.lastUploadedMemory) { _, memory in
            print("🔍 MainView - lastUploadedMemory changed: \(memory?.id ?? UUID())")
            if memory != nil {
                print("✅ MainView - Upload completed, will show Done view after delay")
                
                // 업로드 완료 후 약간의 지연을 두고 Done 뷰 표시
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showUploadProgress = false // 로딩 화면 숨김
                    showDoneView = true
                    print("🔍 MainView - showDoneView is now: \(showDoneView)")
                }
            }
        }
        .onChange(of: viewModel.isThumbnailGenerating) { _, isGenerating in
            showLoadingPopup = isGenerating
        }
        .onChange(of: viewModel.isUploading) { _, isUploading in
            print("🔍 MainView - isUploading changed: \(isUploading)")
            
            // 업로드가 시작되면 Done 뷰를 숨김
            if isUploading {
                showDoneView = false
                showUploadProgress = true
            }
            // 업로드가 끝나도 Done 뷰가 나타날 때까지 로딩 유지
            // (lastUploadedMemory 변경 시에 직접 제어)
            
            print("🔍 MainView - showUploadProgress: \(showUploadProgress)")
        }
        .onReceive(viewModel.$popupData) { popupData in
            showFileSizePopup = popupData != nil
        }
    }
    
    @ViewBuilder
    private var loadingOverlay: some View {
        if viewModel.isThumbnailGenerating {
            iOSUnifiedLoadingView.thumbnail()
        } else if viewModel.isUploading || showUploadProgress {
            // 업로드 상태에 따라 적절한 로딩뷰 표시
            if !viewModel.uploadStatus.isEmpty {
                // 특별한 상태 메시지가 있으면 (CDN 업로딩 등)
                iOSUnifiedLoadingView.uploadWithStatus(
                    fileSize: viewModel.uploadingFileSize,
                    status: viewModel.uploadStatus
                )
            } else if viewModel.uploadProgress > 0 {
                // 진행률이 있으면
                iOSUnifiedLoadingView.uploadWithProgress(
                    fileSize: viewModel.uploadingFileSize,
                    progress: viewModel.uploadProgress
                )
            } else {
                // 기본 업로드
                iOSUnifiedLoadingView.upload(fileSize: viewModel.uploadingFileSize)
            }
        }
    }
    
    // uploadProgressOverlay 제거됨 - 모든 업로드 관련 뷰는 loadingOverlay에서 통합 처리
    
    @ViewBuilder
    private var fileSizePopup: some View {
        if let popupData = viewModel.popupData {
            iOSConfirmationPopupView(
                title: popupData.title,
                message: popupData.notes,
                style: .twoButtons(
                    cancelTitle: popupData.leadingButtonText ?? "Cancel", 
                    confirmTitle: popupData.trailingButtonText
                ),
                onCancel: {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        showFileSizePopup = false
                        showUploadProgress = false  // 업로딩 프로그레스 화면도 함께 숨김
                    }
                    popupData.leadingButtonAction?()
                },
                onConfirm: {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        showFileSizePopup = false
                        showUploadProgress = false  // 업로딩 프로그레스 화면도 함께 숨김
                    }
                    popupData.trailingButtonAction()
                }
            )
            .opacity(showFileSizePopup ? 1.0 : 0.0)
            .zIndex(showFileSizePopup ? 1000 : -1)
            .allowsHitTesting(showFileSizePopup)
        }
    }
}

// MARK: - Video Selection View
struct VideoSelectionView: View {
    @ObservedObject var viewModel: AddMemoryMainViewModel
    
    var body: some View {
        VStack {
            Spacer()
            
            // 비디오 선택 UI
            ZStack {
                // 썸네일 배경 (있는 경우)
                if let thumbnail = viewModel.thumbnailImage {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 132)
                        .clipped()
                        .cornerRadius(20)
                        .overlay(Colors.NebulaBlack.opacity(0.6))
                } else {
                    // 썸네일이 없을 때 기본 배경
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Colors.DimBlack40)
                        .stroke(Colors.GrayStroke)
                }
                
                // 비디오 선택 버튼 (항상 표시)
                PhotosPicker(selection: $viewModel.selectedVideoItem, matching: .spatialMedia) {
                    VStack {
                        Image("uploadWhiteIcon")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                        
                        Text("Select your spatial video")
                            .fontStyle(Fonts.body1)
                            .foregroundColor(Colors.NebulaWhite)
                            .padding(.top, 4)
                    }
                }
                .frame(height: 132)
                .padding(.horizontal, 36)
                .cornerRadius(20)
                .buttonStyle(PlainButtonStyle())
                .onChange(of: viewModel.selectedVideoItem) { _, newItem in
                    viewModel.handleVideoSelection(item: newItem)
                }
            }
            .frame(height: 132)
            .padding(.horizontal, 60) // 양옆에서 24 떨어진 width
            
            Spacer()
            
            // Notice Section
            NoticeSection()
        }
    }
}

// MARK: - Memory Edit View
struct MemoryEditView: View {
    @ObservedObject var viewModel: AddMemoryMainViewModel
    @ObservedObject var appState: AppState
    @Binding var showDoneView: Bool
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // 메인 컨텐츠
            ScrollView {
                VStack {
                    Spacer()
                        .frame(height: 20)
                    
                    ThumbnailSection(viewModel: viewModel)
                    
                    Spacer()
                        .frame(height: 56)
                    
                    CategorySection(viewModel: viewModel)
                    
                    Spacer()
                        .frame(height: 56)
                    
                    TextSection(viewModel: viewModel)
                    
                    Color.clear.frame(height: 120)
                }
                .padding(.horizontal, 24)
            }
            .onTapGesture {
                // 다른 곳을 터치하면 키보드 내리기
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
            
            // Upload Button
            VStack {
                iOSUploadButton (
                    title: "Upload",
                    action: {
                        // 키보드 내리기 (UIApplication 방식 사용)
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        
                        Task {
                            guard let userId = appState.userId else { 
                                print("❌ UserId is nil, cannot upload memory")
                                return 
                            }
                            print("🔍 Starting memory upload for user: \(userId)")
                            await viewModel.saveMemory(note: viewModel.note, title: viewModel.title, userId: userId)
                        }
                    },
                    isEnabled: viewModel.isUploadEnabled && !viewModel.isUploading
                )
                .disabled(!viewModel.isUploadEnabled || viewModel.isUploading)
                .padding(.horizontal, 24)
                .padding(.bottom, 30)
            }
            .background(LinearGradient.BtnBackGrad)
        }
    }
}

// MARK: - Thumbnail Section
struct ThumbnailSection: View {
    @ObservedObject var viewModel: AddMemoryMainViewModel
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Thumbnail")
                .fontStyle(Fonts.title3)
                .foregroundColor(Colors.NebulaWhite)
            
            Spacer()
                .frame(height: 24)
            
            if let thumbnail = viewModel.thumbnailImage {
                ZStack {
                    // 썸네일 배경
                    Image(uiImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 200)
                        .clipped()
                        .cornerRadius(40)
                        .overlay(Colors.NebulaBlack.opacity(0.3))
                    
                    // 비디오 재선택 버튼 (오버레이)
                    PhotosPicker(selection: $viewModel.selectedVideoItem, matching: .spatialMedia) {
                        VStack {
                            Image("uploadWhiteIcon")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)
                            
                            Text("Change video")
                                .fontStyle(Fonts.caption1)
                                .foregroundColor(Colors.NebulaWhite)
                                .padding(.top, 4)
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: 200)
                    .background(
                        RoundedRectangle(cornerRadius: 40)
                            .fill(Colors.NebulaBlack.opacity(0.7))
                            .stroke(Colors.GrayStroke, lineWidth: 1)
                    )
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
}

// MARK: - Category Section
struct CategorySection: View {
    @ObservedObject var viewModel: AddMemoryMainViewModel
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Category")
                .fontStyle(Fonts.title3)
                .foregroundColor(Colors.NebulaWhite)
            
            Spacer()
                .frame(height: 24)
            
            HStack {
                ForEach(Category.allCases, id: \.self) { category in
                    iOSCategoryButton(
                        category: category,
                        isSelected: viewModel.selectedCategory == category,
                        action: {
                            viewModel.toggleCategory(category)
                        }
                    )
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }
}

// MARK: - Text Section
struct TextSection: View {
    @ObservedObject var viewModel: AddMemoryMainViewModel
    @FocusState private var isTitleFocused: Bool
    @FocusState private var isNoteFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Text")
                .fontStyle(Fonts.title3)
                .foregroundColor(Colors.NebulaWhite)
            
            Spacer()
                .frame(height: 24)
            
            VStack(spacing: 0) {
                // Title
                ZStack(alignment: .topLeading) {
                    if viewModel.title.isEmpty && !isTitleFocused {
                        Text("Write the title")
                            .font(.title3)
                            .foregroundColor(Colors.NonCheckedBoxStroke)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 24)
                            .allowsHitTesting(false)
                    }
                    
                    TextField("", text: $viewModel.title)
                        .textFieldStyle(PlainTextFieldStyle())
                        .font(.title3)
                        .foregroundColor(Colors.NebulaWhite)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 24)
                        .focused($isTitleFocused)
                }
                
                Rectangle()
                    .fill(viewModel.note.count >= 500 ? AnyShapeStyle(Colors.NebulaRed) : AnyShapeStyle(LinearGradient.MainStroke))
                    .frame(height: 1)
                
                // Note with character limit
                ZStack(alignment: .topLeading) {
                    if viewModel.note.isEmpty && !isNoteFocused {
                        Text("Write the note")
                            .fontStyle(Fonts.body2)
                            .foregroundColor(Colors.NebulaWhite.opacity(0.5))
                            .padding(.horizontal, 24)
                            .padding(.vertical, 18)
                            .allowsHitTesting(false)
                    }
                    
                    TextEditor(text: $viewModel.note)
                        .font(.system(size: 17, weight: .regular))
                        .foregroundColor(Colors.NebulaWhite)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 18)
                        .frame(minHeight: 180, maxHeight: .infinity)
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                        .focused($isNoteFocused)
                        .onChange(of: viewModel.note) { _, newValue in
                            if newValue.count > 500 {
                                viewModel.note = String(newValue.prefix(500))
                            }
                        }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 30)
                    .stroke(viewModel.note.count >= 500 ? AnyShapeStyle(Colors.NebulaRed) : AnyShapeStyle(LinearGradient.MainStroke), lineWidth: 1)
            )
            
            // Character count and error message outside the box
            HStack {
                if viewModel.note.count >= 500 {
                    Text("The content exceeds the character limit.")
                        .fontStyle(Fonts.caption1)
                        .foregroundColor(Colors.NebulaRed)
                        .opacity(viewModel.note.count >= 500 ? 1.0 : 0.0)
                }
                
                Spacer()
                
                Text("\(viewModel.note.count) / 500")
                    .fontStyle(Fonts.body1)
                    .foregroundStyle(viewModel.note.count >= 500 ? AnyShapeStyle(Colors.NebulaRed) : AnyShapeStyle(LinearGradient.MainGradient))
            }
            .padding(.top, 16)
        }
    }
}

// MARK: - Notice Section
struct NoticeSection: View {
    var body: some View {
        VStack(alignment: .center, spacing: 12) {
            Text("Notice")
                .fontStyle(Fonts.callout)
                .foregroundStyle(Colors.NebulaWhite)
            
            Text("Currently, only videos under 5 minutes can be uploaded. Would you like to continue adding memory star?")
                .fontStyle(Fonts.caption1)
                .foregroundStyle(Colors.NonCheckedBoxStroke)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 70)
        .padding(.bottom, 100)
    }
}
