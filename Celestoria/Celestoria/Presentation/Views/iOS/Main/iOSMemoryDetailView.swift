//
//  iOSMemoryDetailView.swift
//  Celestoria
//
//  Created by Minjun Kim on 7/20/25.
//

import SwiftUI
import AVKit
import CoreMotion

struct iOSMemoryDetailView: View {
    let memory: Memory
    let diContainer: DIContainer
    @StateObject private var viewModel: iOSMemoryDetailViewModel
    @State private var showFullScreenVideo = false
    @State private var thumbnailLoaded = false
    @State private var isPlayingInline = false
    @State private var player: AVPlayer?
    @State private var showCommentSheet = false
    @State private var showLikeSheet = false
    @State private var didLongPressLike = false
    @State private var showOptionMenu = false
    @State private var optionButtonFrame: CGRect = .zero
    @StateObject private var motionManager = MotionManager()
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    init(memory: Memory, diContainer: DIContainer) {
        self.memory = memory
        self.diContainer = diContainer
        self.onBack = nil
        self.onCommentTap = nil
        self.onLikeTap = nil
        _viewModel = StateObject(wrappedValue: iOSMemoryDetailViewModel(
            memory: memory,
            diContainer: diContainer
        ))
    }
    
    init(memory: Memory, diContainer: DIContainer, onBack: @escaping () -> Void) {
        self.memory = memory
        self.diContainer = diContainer
        self.onBack = onBack
        self.onCommentTap = nil
        self.onLikeTap = nil
        _viewModel = StateObject(wrappedValue: iOSMemoryDetailViewModel(
            memory: memory,
            diContainer: diContainer
        ))
    }
    
    init(memory: Memory, diContainer: DIContainer, onBack: @escaping () -> Void, onCommentTap: @escaping () -> Void, onLikeTap: @escaping () -> Void) {
        self.memory = memory
        self.diContainer = diContainer
        self.onBack = onBack
        self.onCommentTap = onCommentTap
        self.onLikeTap = onLikeTap
        _viewModel = StateObject(wrappedValue: iOSMemoryDetailViewModel(
            memory: memory,
            diContainer: diContainer
        ))
    }
    
    private let onBack: (() -> Void)?
    private let onCommentTap: (() -> Void)?
    private let onLikeTap: (() -> Void)?
    
    var body: some View {
        ZStack {
            // Background shadow effect for modal presentation
            Colors.BackgroundBlack
                .ignoresSafeArea(.all)
                .shadow(color: Color(red: 0.4, green: 0.7, blue: 1).opacity(0.9), radius: 8, x: 0, y: 0)
                .shadow(color: Color(red: 0.4, green: 0.7, blue: 1).opacity(0.6), radius: 12, x: 0, y: 0)
            
            VStack(alignment: .leading, spacing: 0) {
                // Custom Navigation Bar with Option Menu
                HStack {
                    Button(action: onBack ?? { dismiss() }) {
                        Image("backButton")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                    }
                    
                    Spacer()
                    
                    // Option Menu Button (only show for non-owners)
                    if !viewModel.isOwner {
                        Button(action: { showOptionMenu.toggle() }) {
                            Image("detailOptionIcon")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)
                        }
                        .background(
                            GeometryReader { geometry in
                                Color.clear
                                    .onAppear {
                                        optionButtonFrame = geometry.frame(in: .global)
                                    }
                                    .onChange(of: geometry.frame(in: .global)) { _, newFrame in
                                        optionButtonFrame = newFrame
                                    }
                            }
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .frame(height: 44)
                .zIndex(1)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        // Gyroscope Video Section
                        GyroscopeVideoView(
                            memory: memory,
                            isPlayingInline: $isPlayingInline,
                            showFullScreenVideo: $showFullScreenVideo,
                            player: $player,
                            motionManager: motionManager
                        )
                        .frame(height: UIScreen.main.bounds.width * 0.56)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // Info Bar
                        HStack(spacing: 20) {
                            // Like button
                            Button(action: {
                                if didLongPressLike { return }
                                Task { await viewModel.toggleLike() }
                            }) {
                                HStack(spacing: 8) {
                                    Image(viewModel.isLiked ? "Like-on" : "likeWhiteIcon")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 24, height: 24)
                                    
                                    Text("\(viewModel.likeCount)")
                                        .fontStyle(Fonts.caption1)
                                        .foregroundStyle(Colors.NebulaWhite)
                                }
                            }
                            .highPriorityGesture(
                                LongPressGesture(minimumDuration: 0.5)
                                    .onEnded { _ in
                                        didLongPressLike = true
                                        if let onLikeTap = onLikeTap {
                                            onLikeTap()
                                        } else {
                                            showLikeSheet = true
                                        }
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                            didLongPressLike = false
                                        }
                                    }
                            )
                            
                            // Comment button
                            Button(action: {
                                if let onCommentTap = onCommentTap {
                                    onCommentTap()
                                } else {
                                    showCommentSheet = true
                                }
                            }) {
                                HStack(spacing: 8) {
                                    Image("commentWhiteIcon")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 24, height: 24)
                                    
                                    Text("\(viewModel.commentCount)")
                                        .fontStyle(Fonts.caption1)
                                        .foregroundStyle(Colors.NebulaWhite)
                                }
                            }
                            
                            Spacer()
                            
                            // Delete button (only for owner)
                            if viewModel.isOwner {
                                Button(action: {
                                    viewModel.showDeleteConfirmation()
                                }) {
                                    Image("trashIcon")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 24, height: 24)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // Memory Info
                        VStack(alignment: .leading, spacing: 0) {
                            // Date
                            Text(viewModel.formattedDate)
                                .fontStyle(Fonts.caption2)
                                .foregroundColor(Colors.NebulaWhite)
                            
                            Spacer()
                                .frame(height: 8)
                            
                            // Title
                            Text(memory.title)
                                .fontStyle(Fonts.title3)
                                .foregroundColor(Colors.NebulaWhite)
                            
                            Spacer()
                                .frame(height: 20)
                            
                            // Note
                            if !memory.note.isEmpty {
                                Text(memory.note)
                                    .font(.system(size: 16))
                                    .foregroundColor(.white.opacity(0.9))
                                    .lineSpacing(4)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            
                            // Owner Info
                            if !viewModel.isOwner {
                                if let profile = viewModel.userProfile {
                                    HStack(spacing: 12) {
                                        Group {
                                            if let profileKey = profile.profileKey,
                                               let predefinedImage = PredefinedProfileImage.fromKey(profileKey) {
                                                Image(predefinedImage.rawValue)
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fill)
                                            } else if let profileImageURL = profile.profileImageURL {
                                                AsyncImage(url: URL(string: profileImageURL)) { image in
                                                    image
                                                        .resizable()
                                                        .aspectRatio(contentMode: .fill)
                                                } placeholder: {
                                                    Circle()
                                                        .fill(Color.gray)
                                                }
                                            } else {
                                                Circle()
                                                    .fill(Color.gray)
                                            }
                                        }
                                        .frame(width: 50, height: 50)
                                        .clipShape(Circle())
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(profile.name)
                                                .font(.system(size: 16, weight: .semibold))
                                                .foregroundColor(.white)
                                        }
                                        
                                        Spacer()
                                    }
                                    .padding(.top, 16)
                                    .padding(.bottom, 8)
                                }
                            }
                        }
                        
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Loading indicator
            if viewModel.isLoading {
                iOSUnifiedLoadingView.memoryDetail()
            }
            
            // Error message
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
                    .onTapGesture {
                        viewModel.clearError()
                    }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            print("🔍 iOSMemoryDetailView appeared - Memory ID: \(memory.id)")
            viewModel.setup(appState: appState)
        }
        .task {
            await viewModel.loadData()
        }
        .overlay(
            ZStack {
                // Option Menu
                if showOptionMenu {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .onTapGesture {
                            showOptionMenu = false
                        }
                    
                    VStack {
                        Spacer()
                        
                        HStack {
                            Spacer()
                            
                            MemoryDetailOptionMenuView(
                                onReportTap: {
                                    showOptionMenu = false
                                    viewModel.showReportPopup()
                                },
                                onBlockUserTap: {
                                    showOptionMenu = false
                                    viewModel.showBlockPopup()
                                },
                                onDismiss: {
                                    showOptionMenu = false
                                },
                                hasAlreadyReported: viewModel.hasAlreadyReported,
                                optionButtonFrame: optionButtonFrame
                            )
                        }
                    }
                }
                
                // Delete Alert Popup
                if viewModel.showDeleteAlert {
                    iOSConfirmationPopupView(
                        title: "Delete Memory Star",
                        message: "Are you sure you want to delete this memory? This action cannot be undone.",
                        style: .twoButtons(cancelTitle: "Cancel", confirmTitle: "Delete", isDestructive: false),
                        onCancel: {
                            withAnimation(.easeInOut(duration: 0.4)) {
                                viewModel.showDeleteAlert = false
                            }
                        },
                        onConfirm: {
                            Task {
                                let success = await viewModel.deleteMemory()
                                if success {
                                    dismiss()
                                }
                            }
                        }
                    )
                }
                
                // Own Like Popup
                if viewModel.showOwnLikePopup {
                    iOSConfirmationPopupView(
                        title: "Cannot Like Your Own Memory",
                        message: "You cannot like your own memory.",
                        style: .singleButton(title: "OK"),
                        onCancel: {
                            withAnimation(.easeInOut(duration: 0.4)) {
                                viewModel.showOwnLikePopup = false
                            }
                        },
                        onConfirm: {
                            withAnimation(.easeInOut(duration: 0.4)) {
                                viewModel.showOwnLikePopup = false
                            }
                        }
                    )
                }
                
                // Already Reported Popup
                if viewModel.showAlreadyReportedPopup {
                    iOSConfirmationPopupView(
                        title: "Already Reported",
                        message: "You have already submitted a report for this post.",
                        style: .singleButton(title: "OK"),
                        onCancel: {
                            withAnimation(.easeInOut(duration: 0.4)) {
                                viewModel.showAlreadyReportedPopup = false
                            }
                        },
                        onConfirm: {
                            withAnimation(.easeInOut(duration: 0.4)) {
                                viewModel.showAlreadyReportedPopup = false
                            }
                        }
                    )
                }
                
                // Report Confirmation Popup
                if viewModel.showReportConfirmation {
                    iOSConfirmationPopupView(
                        title: "Report this post?",
                        message: "Are you sure you want to report this post? This action cannot be undone.",
                        style: .twoButtons(cancelTitle: "No", confirmTitle: "Yes", isDestructive: false),
                        onCancel: {
                            withAnimation(.easeInOut(duration: 0.4)) {
                                viewModel.showReportConfirmation = false
                            }
                        },
                        onConfirm: {
                            Task {
                                await viewModel.reportMemory()
                            }
                        }
                    )
                }
                
                // Block Confirmation Popup
                if viewModel.showBlockConfirmation {
                    iOSConfirmationPopupView(
                        title: "Block this user?",
                        message: "Are you sure you want to block this user? This action cannot be undone.",
                        style: .twoButtons(cancelTitle: "No", confirmTitle: "Yes", isDestructive: false),
                        onCancel: {
                            withAnimation(.easeInOut(duration: 0.4)) {
                                viewModel.showBlockConfirmation = false
                            }
                        },
                        onConfirm: {
                            Task {
                                await viewModel.blockUser()
                            }
                        }
                    )
                }
                
                // Report Completion Popup
                if viewModel.showReportCompletion {
                    iOSConfirmationPopupView(
                        title: "Report submitted!",
                        message: "Our team will review this post shortly.",
                        style: .singleButton(title: "Complete"),
                        onCancel: {
                            withAnimation(.easeInOut(duration: 0.4)) {
                                viewModel.showReportCompletion = false
                                dismiss() // 메모리 닫기
                            }
                        },
                        onConfirm: {
                            withAnimation(.easeInOut(duration: 0.4)) {
                                viewModel.showReportCompletion = false
                                dismiss() // 메모리 닫기
                            }
                        }
                    )
                }
                
                // Block Completion Popup
                if viewModel.showBlockCompletion {
                    iOSConfirmationPopupView(
                        title: "User blocked!",
                        message: "Manage blocked users in Settings",
                        style: .singleButton(title: "Complete"),
                        onCancel: {
                            withAnimation(.easeInOut(duration: 0.4)) {
                                viewModel.showBlockCompletion = false
                                // Send notification to close explore user space
                                NotificationCenter.default.post(name: AppState.forceCloseExploreUserSpace, object: nil)
                                // Close detail immediately (pop 1st)
                                dismiss()
                                // Reload Explore after closing
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                    appState.refreshExplore = true
                                }
                            }
                        },
                        onConfirm: {
                            withAnimation(.easeInOut(duration: 0.4)) {
                                viewModel.showBlockCompletion = false
                                // Send notification to close explore user space
                                NotificationCenter.default.post(name: AppState.forceCloseExploreUserSpace, object: nil)
                                // Close detail immediately (pop 1st)
                                dismiss()
                                // Reload Explore after closing
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                    appState.refreshExplore = true
                                }
                            }
                        }
                    )
                }
            }
        )
        .fullScreenCover(isPresented: $showFullScreenVideo) {
            if let videoURLString = memory.videoURL,
               let videoURL = URL(string: videoURLString) {
                ZStack {
                    Color.black
                        .edgesIgnoringSafeArea(.all)
                    
                    // Use the existing player if available, otherwise create new one
                    VideoPlayer(player: player ?? AVPlayer(url: videoURL))
                        .edgesIgnoringSafeArea(.all)
                        .onAppear {
                            // 동기화를 위해 기존 플레이어 재사용
                            if player == nil {
                                player = AVPlayer(url: videoURL)
                            }
                            // 약간의 지연 후 재생으로 동기화 보장
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                player?.play()
                            }
                        }
                        .onDisappear {
                            // Pause when leaving fullscreen
                            player?.pause()
                        }
                    
                    // Close button
                    VStack {
                        HStack {
                            Spacer()
                            Button(action: {
                                showFullScreenVideo = false
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 30))
                                    .foregroundColor(.white.opacity(0.8))
                                    .padding()
                            }
                        }
                        Spacer()
                    }
                }
            } else {
                Text("Video not available")
                    .font(.title)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        showFullScreenVideo = false
                    }
            }
        }
        .sheet(isPresented: $showCommentSheet) {
            CommentSheetView(memory: memory, diContainer: diContainer)
        }
        .sheet(isPresented: $showLikeSheet) {
            LikeSheetView(memory: memory, diContainer: diContainer)
        }
    }
}
