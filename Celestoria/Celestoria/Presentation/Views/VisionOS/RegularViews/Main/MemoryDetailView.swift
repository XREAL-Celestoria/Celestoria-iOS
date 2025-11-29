//
//  MemoryDetailView.swift
//  Celestoria
//
//  Created by Park Seyoung on 1/27/25.
//

import SwiftUI
import os
import AVKit

struct MemoryDetailView: View {
    @StateObject private var viewModel: MemoryDetailViewModel
    @EnvironmentObject var spaceCoordinator: SpaceCoordinator
    @EnvironmentObject var appState: AppState
    @Environment(\.dismissWindow) private var dismissWindow
    @Environment(\.openWindow) private var openWindow
    @Environment(\.scenePhase) private var scenePhase
    @State private var showFullScreenVideo: Bool = false
    @State private var thumbnailLoaded: Bool = false
    @State private var commentText: String = ""
    @FocusState private var isCommentFieldFocused: Bool
    
    // 두 개 이상의 인스턴스가 Main 창 열기 요청을 중복하지 않게 하기 위한 static 변수
    private static var didTriggerMainWindowOpen: Bool = false

    // 노티피케이션 옵저버를 static으로 관리
    private static var memoryDetailObserver: NSObjectProtocol?
    private static var mainObserver: NSObjectProtocol?
    
    // MemoryDetailView는 모든 scene 관련 처리를 내부에서 수행합니다.
    init(memory: Memory,
         memoryRepository: MemoryRepository,
         profileUseCase: ProfileUseCase,
         authRepository: AuthRepositoryProtocol,
         appState: AppState,
         spaceCoordinator: SpaceCoordinator,
         commentUseCase: CommentUseCase? = nil) {
        _viewModel = StateObject(wrappedValue: MemoryDetailViewModel(
            memory: memory,
            memoryRepository: memoryRepository,
            profileUseCase: profileUseCase,
            authRepository: authRepository,
            appState: appState,
            spaceCoordinator: spaceCoordinator,
            commentUseCase: commentUseCase
        ))
    }
    
    var body: some View {
        GradientBorderContainer {
            GeometryReader { geometry in
                HStack(spacing: 0) {
                    // 왼쪽 영역 (2/3) - ZStack으로 구성 (썸네일이 전체를 차지하고 네비게이션이 overlay)
                    ZStack {
                        // 썸네일이 전체 영역 차지 (1-2-4-5-7-8)
                        VStack(spacing: 0) {
                            // 썸네일 영역 (상단 65%)
                            thumbnailImageSection(geometry: geometry, width: geometry.size.width * 0.67)
                                .frame(height: geometry.size.height * 0.65)
                            
                            // 정보 영역 (하단 35%)
                            MemoryInfoView(viewModel: viewModel)
                                .frame(width: geometry.size.width * 0.67, height: geometry.size.height * 0.35)
                        }
                        
                        // Navigation Bar를 최상단에 overlay
                        VStack {
                            NavigationBarWithMenu(
                                title: "Memory Detail",
                                leftAction: {
                                    dismissWindow(id: "Memory-Detail")
                                },
                                leftButtonImageString: "xmark",
                                showMenuButton: appState.userId != viewModel.memory.userId,
                                reportAction: { viewModel.showReportPopup() },
                                blockAction: { viewModel.showBlockPopup() }
                            )
                            .padding(.horizontal, 28)
                            .padding(.top, 28)
                            .frame(height: 80)
                            
                            Spacer()
                        }
                    }
                    .frame(width: geometry.size.width * 0.67)
                    
                    // 오른쪽 영역 (1/3) - 댓글
                    CommentsSection(
                        viewModel: viewModel,
                        commentText: $commentText,
                        isCommentFieldFocused: $isCommentFieldFocused
                    )
                    .frame(width: geometry.size.width * 0.33)
                    .background(Colors.NebulaBlack.opacity(0.3))
                }
            }
            
            // Loading & Error overlays
            if viewModel.isLoading || viewModel.isDeleting {
                ZStack {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                    ProgressView("Loading...")
                        .frame(width: 120, height: 120)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(12)
                        .foregroundColor(.white)
                }
            }
            
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .bold()
                    .padding()
                    .background(Color.white)
                    .cornerRadius(8)
                    .shadow(radius: 4)
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .fullScreenCover(isPresented: $showFullScreenVideo) {
            if let videoURL = viewModel.memory.videoURL, let url = URL(string: videoURL) {
                CelestoriaVideoPlayerView(videoURL: url)
                    .edgesIgnoringSafeArea(.all)
                    .background(Color.black)
                    .onTapGesture { showFullScreenVideo = false }
            } else {
                Text("Video not available")
                    .font(.title)
                    .foregroundColor(.white)
                    .background(Color.black)
                    .edgesIgnoringSafeArea(.all)
            }
        }
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
        .onAppear {
            setupNotificationObservers()
            // 메모리 창이 열렸음을 추적
            Task { @MainActor in
                MemoryWindowManager.shared.onMemoryWindowOpened(memoryId: viewModel.memory.id)
            }
        }
        .onDisappear {
            cleanupNotificationObservers()
            // 메모리 창이 닫혔음을 추적
            Task { @MainActor in
                MemoryWindowManager.shared.onMemoryWindowClosed(memoryId: viewModel.memory.id)
            }
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active && !appState.mainWindowActive {
                if !Self.didTriggerMainWindowOpen {
                    os.Logger.info("MemoryDetailView: MainView is not active. Opening Main window.")
                    Self.didTriggerMainWindowOpen = true
                    openWindow(id: "Main")
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        Self.didTriggerMainWindowOpen = false
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func thumbnailImageSection(geometry: GeometryProxy, width: CGFloat) -> some View {
        ZStack {
            if let thumbnailURL = URL(string: viewModel.memory.thumbnailURL ?? "") {
                AsyncImage(url: thumbnailURL) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(width: 44, height: 44)
                            .onAppear { thumbnailLoaded = false }
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: width, height: geometry.size.height * 0.65)
                            .clipped()
                            .overlay(Colors.NebulaBlack.opacity(0.3))
                            .onAppear { thumbnailLoaded = true }
                    case .failure:
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                    @unknown default:
                        EmptyView()
                    }
                }
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
            }
            
            // Play button overlay
            CircularButton(action: {
                os.Logger.info("Playing")
                showFullScreenVideo = true
            }, buttonImageString: "play.fill")
            .frame(width: 60, height: 60)
        }
    }
    
    private func setupNotificationObservers() {
        // 기존 노티피케이션 옵저버 제거 처리
        if let observer = Self.memoryDetailObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if let observer = Self.mainObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        
        // Report 완료 시 MemoryDetailView만 닫기
        Self.memoryDetailObserver = NotificationCenter.default.addObserver(
            forName: .dismissMemoryDetailViewOnly,
            object: nil,
            queue: .main
        ) { _ in
            dismissWindow(id: "Memory-Detail")
        }
        
        // Block 완료 시 모든 창 닫고 Main 창 열기
        Self.mainObserver = NotificationCenter.default.addObserver(
            forName: .dismissAllAndGoMain,
            object: nil,
            queue: .main
        ) { _ in
            dismissWindow(id: "Memory-Detail")
            appState.showExploreNavigatorView = false
            dismissWindow(id: "Explore-Navigator")
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                appState.activeScreen = .explore
                openWindow(id: "Main")
                
                Task {
                    if let userId = appState.userId {
                        await spaceCoordinator.loadData(for: userId)
                    }
                }
            }
        }
    }
    
    private func cleanupNotificationObservers() {
        if let observer = Self.memoryDetailObserver {
            NotificationCenter.default.removeObserver(observer)
            Self.memoryDetailObserver = nil
        }
        if let observer = Self.mainObserver {
            NotificationCenter.default.removeObserver(observer)
            Self.mainObserver = nil
        }
    }
}

// 기존 MemoryInfoView 복원
struct MemoryInfoView: View {
    @ObservedObject var viewModel: MemoryDetailViewModel
    @Environment(\.dismissWindow) private var dismissWindow
    @EnvironmentObject var spaceCoordinator: SpaceCoordinator
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            VisualEffectBlur(style: .systemMaterial)
                .edgesIgnoringSafeArea(.all)
            
            Rectangle()
                .fill(Color.clear)
                .overlay(
                    Colors.NebulaBlack.opacity(0.3)
                        .shadow(.inner(color: Colors.NebulaWhite.opacity(0.8), radius: 24))
                )
                .edgesIgnoringSafeArea(.all)
            
            HStack(alignment: .top) {
                profileImageSection
                    .padding(.leading, 60)
                    .padding(.top, 28)
                
                Spacer()
                
                VStack(alignment: .leading) {
                    HStack {
                        Text(viewModel.formattedDate)
                            .foregroundColor(Colors.NebulaWhite)
                            .font(.system(size: 12, weight: .medium))
                        Spacer()
                    }
                    Text(viewModel.memory.title)
                        .foregroundColor(Colors.NebulaWhite)
                        .font(.system(size: 24, weight: .bold))
                        .padding(.top, 0)
                    
                    Text(viewModel.memory.note)
                        .foregroundColor(.white)
                        .font(.system(size: 14, weight: .medium))
                        .frame(maxWidth: 1075, alignment: .topLeading)
                        .padding(.top, 8)
                    
                    Spacer()
                    
                    // 좋아요 버튼
                    HStack {
                        Button(action: {
                            let wasLiked = viewModel.isLiked
                            Task {
                                await viewModel.toggleLike()
                                if !wasLiked && viewModel.isLiked {
                                    spaceCoordinator.playLikeAnimation()
                                }
                            }
                        }) {
                            HStack(spacing: 12) {
                                Image(viewModel.isLiked ? "Like-on" : "Like")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 24, height: 24)
                                
                                Text("\(viewModel.likeCount)")
                                    .foregroundColor(Colors.NebulaWhite)
                                    .font(.system(size: 21, weight: .medium))
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        .disabled(viewModel.isLikeLoading)
                        .opacity(viewModel.isLikeLoading ? 0.6 : 1.0)
                        
                        Spacer()
                    }
                    .padding(.bottom, 30)
                }
                .padding(.leading, 8)
                .padding(.top, 28)
            }
            
            if let currentUserId = appState.userId,
               currentUserId == viewModel.memory.userId {
                Button(action: {
                    viewModel.showDeletePopup(
                        dismissWindow: { dismissWindow(id: "Memory-Detail") },
                        onMemoryDeleted: { _ in
                            Task { await spaceCoordinator.loadData(for: currentUserId) }
                        }
                    )
                }) {
                    Image("DeleteButton")
                        .resizable()
                        .scaledToFit()
                }
                .frame(width: 44, height: 44)
                .padding(.trailing, 56)
                .padding(.top, 32)
                .buttonStyle(MainButtonStyle())
            }
        }
    }
    
    @ViewBuilder
    private var profileImageSection: some View {
        if let userProfile = viewModel.userProfile {
            if let key = userProfile.profileKey,
               let predefined = PredefinedProfileImage.fromKey(key) {
                // ✅ 기본 이미지 보여주기
                Image(predefined.rawValue)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 52, height: 52)
                    .clipShape(Circle())
            } else if let urlString = userProfile.profileImageURL,
                      let url = URL(string: urlString) {
                // ✅ 커스텀 이미지
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(width: 24, height: 24)
                    case .success(let image):
                        image.resizable()
                            .scaledToFill()
                            .frame(width: 52, height: 52)
                            .clipShape(Circle())
                    case .failure(_):
                        Image("CardUserProfileImage")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 52, height: 52)
                            .clipShape(Circle())
                    @unknown default:
                        EmptyView()
                    }
                }
            } else {
                // 둘 다 없을 때 fallback
                Image("CardUserProfileImage")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 52, height: 52)
                    .clipShape(Circle())
            }
        } else {
            Image("CardUserProfileImage")
                .resizable()
                .scaledToFill()
                .frame(width: 52, height: 52)
                .clipShape(Circle())
        }
    }
}

// 댓글 섹션 (오른쪽 1/3)
struct CommentsSection: View {
    @ObservedObject var viewModel: MemoryDetailViewModel
    @Binding var commentText: String
    var isCommentFieldFocused: FocusState<Bool>.Binding
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var diContainer: DIContainer
    @State private var textFieldId = UUID()
    
    var body: some View {
        VStack(spacing: 0) {
            // 댓글 헤더
            HStack {
                Text("Comments")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Colors.NebulaWhite)
                
                if viewModel.comments.count > 0 {
                    Text("(\(viewModel.comments.count))")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(Colors.NebulaWhite.opacity(0.7))
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Colors.NebulaBlack.opacity(0.2))
            
            Divider()
                .background(Colors.NebulaWhite.opacity(0.2))
            
            // 댓글 리스트
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if viewModel.isLoadingComments {
                        HStack {
                            Spacer()
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                            Spacer()
                        }
                        .padding(.vertical, 40)
                    } else if viewModel.comments.isEmpty {
                        Text("Be the first to comment")
                            .font(.system(size: 14))
                            .foregroundColor(Colors.NebulaWhite.opacity(0.5))
                            .padding(.top, 40)
                            .frame(maxWidth: .infinity)
                    } else {
                        ForEach(viewModel.comments, id: \.comment.id) { item in
                            CommentItemView(
                                comment: item.comment,
                                userProfile: item.userProfile,
                                currentUserId: appState.userId,
                                isEditing: viewModel.editingCommentId == item.comment.id,
                                editingText: viewModel.editingCommentText,
                                onEdit: { 
                                    viewModel.startEditingComment(item.comment.id, currentText: item.comment.content)
                                },
                                onSaveEdit: { 
                                    Task { await viewModel.saveEditedComment() }
                                },
                                onCancelEdit: { 
                                    viewModel.cancelEditingComment() 
                                },
                                onDelete: { 
                                    Task { await viewModel.deleteComment(item.comment.id) }
                                },
                                onEditingTextChange: { newText in 
                                    viewModel.editingCommentText = newText 
                                }
                            )
                            .padding(.horizontal, 20)
                        }
                    }
                }
                .padding(.vertical, 12)
            }
            
            Divider()
                .background(Colors.NebulaWhite.opacity(0.2))
            
            // 댓글 입력창
            HStack(spacing: 12) {
                // Profile image
                if let currentUserId = appState.userId {
                    AsyncProfileImage(userId: currentUserId, size: 36)
                }
                
                // Input field
                ZStack(alignment: .leading) {
                    if viewModel.commentText.isEmpty {
                        Text("Add a comment...")
                            .foregroundColor(Colors.NebulaWhite.opacity(0.5))
                            .font(.system(size: 14))
                    }
                    
                    TextField("", text: $viewModel.commentText)
                        .id(textFieldId)
                        .textFieldStyle(PlainTextFieldStyle())
                        .foregroundColor(Colors.NebulaWhite)
                        .font(.system(size: 14))
                        .focused(isCommentFieldFocused)
                        .disabled(viewModel.isPostingComment)
                        .onSubmit {
                            Task { 
                                await viewModel.addComment()
                                // TextField 재생성 및 포커스 유지
                                textFieldId = UUID()
                                try? await Task.sleep(nanoseconds: 10_000_000) // 0.01초
                                await MainActor.run {
                                    isCommentFieldFocused.wrappedValue = true
                                }
                            }
                        }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Colors.NebulaBlack.opacity(0.5))
                )
                
                // Send button
                Button(action: {
                    Task { 
                        await viewModel.addComment()
                        // TextField 재생성 및 포커스 유지
                        textFieldId = UUID()
                        try? await Task.sleep(nanoseconds: 10_000_000) // 0.01초
                        await MainActor.run {
                            isCommentFieldFocused.wrappedValue = true
                        }
                    }
                }) {
                    if viewModel.isPostingComment {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .frame(width: 20, height: 20)
                    } else {
                        Image(systemName: "paperplane.fill")
                            .foregroundColor(viewModel.commentText.isEmpty ? 
                                Colors.NebulaWhite.opacity(0.3) : Colors.StarfieldPurple)
                            .font(.system(size: 18))
                    }
                }
                .disabled(viewModel.commentText.isEmpty || viewModel.isPostingComment)
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Colors.NebulaBlack.opacity(0.4))
        }
    }
}

// 호환성을 위한 빈 뷰들
struct MemoryInfoAndCommentsView: View {
    @ObservedObject var viewModel: MemoryDetailViewModel
    var body: some View { EmptyView() }
}

struct CommentInputToolbar: View {
    @ObservedObject var viewModel: MemoryDetailViewModel
    @FocusState.Binding var isCommentFieldFocused: Bool
    var body: some View { EmptyView() }
}