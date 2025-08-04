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
    @State private var showFullScreenVideo = false
    @State private var thumbnailLoaded = false
    @State private var ownerProfile: UserProfile?
    @State private var showDeleteConfirmation = false
    @State private var likeCount: Int = 0
    @State private var commentCount: Int = 0 // Comments feature not implemented
    @State private var isLiked: Bool = false
    @State private var isLikeLoading: Bool = false
    @State private var isPlayingInline = false
    @State private var player: AVPlayer?
    @State private var rotationX: Double = 0
    @State private var rotationY: Double = 0
    @StateObject private var motionManager = MotionManager()
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    // URL 토큰 갱신을 위한 상태
    @State private var refreshedThumbnailURL: String?
    @State private var refreshedVideoURL: String?
    @State private var isRefreshingURLs = false
    
    init(memory: Memory, diContainer: DIContainer) {
        self.memory = memory
        self.diContainer = diContainer
        print("=== iOSMemoryDetailView INIT ===")
        print("Memory received:")
        print("  - ID: \(memory.id)")
        print("  - Title: \(memory.title)")
        print("  - Note: \(memory.note)")
        print("  - Category: \(memory.category)")
        print("  - VideoURL: \(memory.videoURL ?? "nil")")
        print("  - ThumbnailURL: \(memory.thumbnailURL ?? "nil")")
        print("=== END INIT ===")
    }
    
    var body: some View {
        ZStack {
            // Background shadow effect for modal presentation
            Colors.BackgroundBlack
                .ignoresSafeArea()
                .shadow(color: Color(red: 0.4, green: 0.7, blue: 1).opacity(0.9), radius: 8, x: 0, y: 0)
                .shadow(color: Color(red: 0.4, green: 0.7, blue: 1).opacity(0.6), radius: 12, x: 0, y: 0)
            
            VStack {
                iOSNavigationView(title: "", onBack: {dismiss()})
                    .zIndex(1)
                
                Spacer()
                    .frame(height: 8)
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Gyroscope Video Section
                        GyroscopeVideoView(
                            memory: memory,
                            refreshedThumbnailURL: refreshedThumbnailURL,
                            refreshedVideoURL: refreshedVideoURL,
                            isPlayingInline: $isPlayingInline,
                            showFullScreenVideo: $showFullScreenVideo,
                            player: $player,
                            motionManager: motionManager
                        )
                        .frame(height: UIScreen.main.bounds.width * 0.56)
                        
                        // Info Bar
                        HStack(spacing: 20) {
                            // Like button
                            Button(action: {
                                Task {
                                    await toggleLike()
                                }
                            }) {
                                HStack(spacing: 8) {
                                    // TODO: - 수정 필요
                                    Image(isLiked ? "likeWhiteIcon" : "likeWhiteIcon")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 24, height: 24)
                                    
                                    Text("\(likeCount)")
                                        .fontStyle(Fonts.caption1)
                                        .foregroundStyle(Colors.NebulaWhite)
                                }
                            }
                            .disabled(isLikeLoading || memory.userId == appState.userId)
                            
                            // Comment count
                            HStack(spacing: 8) {
                                Image("commentWhiteIcon")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 24, height: 24)
                                
                                Text("\(commentCount)")
                                    .fontStyle(Fonts.caption1)
                                    .foregroundStyle(Colors.NebulaWhite)
                            }
                            
                            Spacer()
                            
                            // Delete button (only for owner)
                            if memory.userId == appState.userId {
                                Button(action: {
                                    showDeleteConfirmation = true
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
                        
                        // Memory Info
                        VStack(alignment: .leading) {
                            // Category and Date
                            // Date
                            Text(formatDate(memory.createdAt))
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
                            if let profile = ownerProfile {
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
                                        Text("Owner")
                                            .font(.system(size: 14))
                                            .foregroundColor(.white.opacity(0.6))
                                    }
                                    
                                    Spacer()
                                }
                                .padding(.top, 16)
                                .padding(.bottom, 8)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .overlay(
            Group {
                if showDeleteConfirmation {
                    DeleteMemoryConfirmationPopup(
                        onCancel: {
                            showDeleteConfirmation = false
                        },
                        onDelete: {
                            Task {
                                do {
                                    // URL에서 경로 추출
                                    let videoPath = extractPathFromURL(memory.videoURL)
                                    let thumbnailPath = extractPathFromURL(memory.thumbnailURL)
                                    
                                    // 메모리 삭제
                                    try await diContainer.deleteMemoryUseCase.execute(
                                        memoryId: memory.id,
                                        videoPath: videoPath,
                                        thumbnailPath: thumbnailPath
                                    )
                                    
                                    // 메인뷰 리프레시
                                    appState.refreshMainView = true
                                    
                                    // 상세뷰 닫기
                                    dismiss()
                                    
                                    print("✅ DEBUG: Memory deleted successfully and main view refreshed")
                                } catch {
                                    print("❌ ERROR: Failed to delete memory: \(error)")
                                }
                            }
                        }
                    )
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                }
            }
        )
        .task {
            // Task 취소 체크
            guard !Task.isCancelled else {
                print("ℹ️ INFO: Memory detail view task cancelled before starting")
                return
            }
            
            // 병렬 실행
            async let ownerProfileTask = loadOwnerProfile()
            async let likeDataTask = loadLikeData()
            async let refreshURLsTask = refreshURLs()
            
            // 모든 작업 완료 대기
            await ownerProfileTask
            await likeDataTask
            await refreshURLsTask
            
            print("✅ INFO: Memory detail view data loaded successfully")
        }
        .fullScreenCover(isPresented: $showFullScreenVideo) {
            let videoURLToUse = refreshedVideoURL ?? memory.videoURL
            if let videoURLString = videoURLToUse,
               let videoURL = URL(string: videoURLString) {
                ZStack {
                    Color.black
                        .edgesIgnoringSafeArea(.all)
                    
                    VideoPlayer(player: AVPlayer(url: videoURL))
                        .edgesIgnoringSafeArea(.all)
                    
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
    }
    
    private func loadOwnerProfile() async {
        guard !Task.isCancelled else {
            print("ℹ️ INFO: Owner profile loading cancelled")
            return
        }
        
        do {
            ownerProfile = try await diContainer.profileUseCase.fetchProfileByUserId(userId: memory.userId)
        } catch {
            if Task.isCancelled {
                print("ℹ️ INFO: Owner profile loading cancelled during request")
            } else {
                print("Error loading owner profile: \(error)")
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "yyyy.MM.dd HH:mm"
        return displayFormatter.string(from: date)
    }
    
    // URL에서 경로 추출하는 헬퍼 메서드
    private func extractPathFromURL(_ urlString: String?) -> String? {
        guard let urlString = urlString,
              let url = URL(string: urlString) else {
            return nil
        }
        
        let pathComponents = url.pathComponents
        
        // files.applevisionpro.xyz 형식: /celestoria/thumbnails/path/to/file
        if urlString.contains("files.applevisionpro.xyz") {
            if pathComponents.count >= 4 {
                let bucketName = pathComponents[2] // thumbnails 또는 spatial_videos
                let filePath = pathComponents.dropFirst(3).joined(separator: "/")
                return "\(bucketName)/\(filePath)"
            }
        }
        
        // Supabase 형식: /storage/v1/object/sign/thumbnails/path/to/file
        if let signIndex = pathComponents.firstIndex(of: "sign"),
           signIndex + 1 < pathComponents.count {
            let bucketName = pathComponents[signIndex + 1]
            let filePath = pathComponents.dropFirst(signIndex + 2).joined(separator: "/")
            return "\(bucketName)/\(filePath)"
        }
        
        return nil
    }
    
    private func loadLikeData() async {
        guard let currentUserId = appState.userId else { return }
        guard !Task.isCancelled else {
            print("ℹ️ INFO: Like data loading cancelled")
            return
        }
        
        do {
            // Load like count and current user's like status
            async let likeCountResult = diContainer.memoryRepository.getLikeCount(for: memory.id)
            async let hasLikedResult = diContainer.memoryRepository.hasLiked(memoryId: memory.id, userId: currentUserId)
            
            let (count, liked) = try await (likeCountResult, hasLikedResult)
            
            guard !Task.isCancelled else {
                print("ℹ️ INFO: Like data loading cancelled after request")
                return
            }
            
            likeCount = count
            isLiked = liked
        } catch {
            if Task.isCancelled {
                print("ℹ️ INFO: Like data loading cancelled during request")
            } else {
                print("Error loading like data: \(error)")
            }
        }
    }
    
    private func toggleLike() async {
        guard let currentUserId = appState.userId else { return }
        guard !isLikeLoading else { return }
        
        // Check if user is trying to like their own memory
        if memory.userId == currentUserId {
            return
        }
        
        isLikeLoading = true
        defer { isLikeLoading = false }
        
        do {
            if isLiked {
                // Unlike
                try await diContainer.memoryRepository.deleteLike(memoryId: memory.id, userId: currentUserId)
                likeCount = max(0, likeCount - 1)
                isLiked = false
            } else {
                // Like
                try await diContainer.memoryRepository.createLike(memoryId: memory.id, userId: currentUserId)
                likeCount += 1
                isLiked = true
            }
        } catch {
            print("Error toggling like: \(error)")
        }
    }
    
    // URL 토큰 갱신
    private func refreshURLs() async {
        guard !isRefreshingURLs else { return }
        
        isRefreshingURLs = true
        defer { isRefreshingURLs = false }
        
        print("🔄 DEBUG: Refreshing URLs...")
        
        // 썸네일 URL 갱신
        if let thumbnailURL = memory.thumbnailURL {
            print("🔄 DEBUG: Refreshing thumbnail URL...")
            // 이미 직접 접근 가능한 URL인지 확인
            if thumbnailURL.contains("files.applevisionpro.xyz") {
                print("🔍 DEBUG: Thumbnail URL is already accessible, no need to refresh")
                refreshedThumbnailURL = thumbnailURL
            } else {
                // Supabase URL인 경우 갱신 시도
                do {
                    let refreshedURL = try await diContainer.memoryRepository.refreshThumbnailURL(for: memory)
                    if let refreshedURL = refreshedURL {
                        refreshedThumbnailURL = refreshedURL
                        print("🔄 DEBUG: New thumbnail URL: \(refreshedURL)")
                    }
                } catch {
                    print("⚠️ WARNING: Failed to refresh thumbnail URL, using original: \(error)")
                    // 에러 발생 시 원본 URL 사용
                    refreshedThumbnailURL = thumbnailURL
                }
            }
        }
        
        // 비디오 URL 갱신
        if let videoURL = memory.videoURL {
            print("🔄 DEBUG: Refreshing video URL...")
            // 이미 직접 접근 가능한 URL인지 확인
            if videoURL.contains("files.applevisionpro.xyz") {
                print("🔍 DEBUG: Video URL is already accessible, no need to refresh")
                refreshedVideoURL = videoURL
            } else {
                // Supabase URL인 경우 갱신 시도
                do {
                    let refreshedURL = try await diContainer.memoryRepository.refreshVideoURL(for: memory)
                    if let refreshedURL = refreshedURL {
                        refreshedVideoURL = refreshedURL
                        print("🔄 DEBUG: New video URL: \(refreshedURL)")
                    }
                } catch {
                    print("⚠️ WARNING: Failed to refresh video URL, using original: \(error)")
                    // 에러 발생 시 원본 URL 사용
                    refreshedVideoURL = videoURL
                }
            }
        }
    }
}

// MARK: - Motion Manager
class MotionManager: ObservableObject {
    private let motionManager = CMMotionManager()
    @Published var pitch: Double = 0
    @Published var roll: Double = 0
    
    // Baseline values for calibration
    private var baselinePitch: Double = 0
    private var baselineRoll: Double = 0
    private var calibrationTimer: Timer?
    private let calibrationSpeed: Double = 0.1 // Higher = faster calibration
    private var isInitialized = false
    
    init() {
        if motionManager.isDeviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
            motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
                guard let motion = motion else { return }
                
                // Initialize baseline on first update
                if !(self?.isInitialized ?? false) {
                    self?.baselinePitch = motion.attitude.pitch
                    self?.baselineRoll = motion.attitude.roll
                    self?.isInitialized = true
                }
                
                self?.updateRotation(motion: motion)
            }
            
            // Start calibration timer
            calibrationTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                self?.calibrateBaseline()
            }
        }
    }
    
    private func updateRotation(motion: CMDeviceMotion) {
        let rawPitch = motion.attitude.pitch
        let rawRoll = motion.attitude.roll
        
        // Apply differential rotation (current - baseline)
        pitch = rawPitch - baselinePitch
        roll = rawRoll - baselineRoll
    }
    
    private func calibrateBaseline() {
        guard let motion = motionManager.deviceMotion else { return }
        
        let targetPitch = motion.attitude.pitch
        let targetRoll = motion.attitude.roll
        
        // Slowly lerp baseline towards current orientation
        baselinePitch += (targetPitch - baselinePitch) * calibrationSpeed
        baselineRoll += (targetRoll - baselineRoll) * calibrationSpeed
    }
    
    deinit {
        calibrationTimer?.invalidate()
        motionManager.stopDeviceMotionUpdates()
    }
    
}

// MARK: - Gyroscope Video View
struct GyroscopeVideoView: View {
    let memory: Memory
    let refreshedThumbnailURL: String?
    let refreshedVideoURL: String?
    @Binding var isPlayingInline: Bool
    @Binding var showFullScreenVideo: Bool
    @Binding var player: AVPlayer?
    @ObservedObject var motionManager: MotionManager
    @State private var thumbnailLoaded = false
    @State private var imageLoadError = false
    
    var body: some View {
        GeometryReader { geometry in
            // Card container with gyroscope effect
            ZStack {
                // Video card with 3D rotation
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.black)
                    .frame(width: geometry.size.width * 0.9, height: geometry.size.width * 0.5)
                    .overlay(
                        ZStack {
                            // Thumbnail or video content
                            if let thumbnailURLString = refreshedThumbnailURL ?? memory.thumbnailURL,
                               let thumbnailURL = URL(string: thumbnailURLString) {
                                
                                if isPlayingInline, let player = player {
                                    // Video player
                                    VideoPlayer(player: player)
                                        .frame(width: geometry.size.width * 0.9, height: geometry.size.width * 0.5)
                                        .clipShape(RoundedRectangle(cornerRadius: 20))
                                        .onAppear {
                                            player.play()
                                        }
                                        .onDisappear {
                                            player.pause()
                                        }
                                } else {
                                    // Thumbnail with proper loading state management
                                    AsyncImage(url: thumbnailURL) { phase in
                                        switch phase {
                                        case .empty:
                                            // Loading state
                                            RoundedRectangle(cornerRadius: 20)
                                                .fill(Color.gray.opacity(0.3))
                                                .frame(width: geometry.size.width * 0.9, height: geometry.size.width * 0.5)
                                                .overlay(
                                                    ProgressView()
                                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                                )
                                        case .success(let image):
                                            // Successfully loaded image
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: geometry.size.width * 0.9, height: geometry.size.width * 0.5)
                                                .clipShape(RoundedRectangle(cornerRadius: 20))
                                                .onAppear {
                                                    thumbnailLoaded = true
                                                    imageLoadError = false
                                                }
                                        case .failure(let error):
                                            // Failed to load image
                                            RoundedRectangle(cornerRadius: 20)
                                                .fill(Color.gray.opacity(0.3))
                                                .frame(width: geometry.size.width * 0.9, height: geometry.size.width * 0.5)
                                                .overlay(
                                                    VStack {
                                                        Image(systemName: "photo")
                                                            .font(.system(size: 30))
                                                            .foregroundColor(.white.opacity(0.6))
                                                        Text("Failed to load image")
                                                            .font(.caption)
                                                            .foregroundColor(.white.opacity(0.6))
                                                    }
                                                )
                                                .onAppear {
                                                    imageLoadError = true
                                                }
                                        @unknown default:
                                            // Unknown state
                                            RoundedRectangle(cornerRadius: 20)
                                                .fill(Color.gray.opacity(0.3))
                                                .frame(width: geometry.size.width * 0.9, height: geometry.size.width * 0.5)
                                        }
                                    }
                                }
                            } else {
                                // No thumbnail URL available
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: geometry.size.width * 0.9, height: geometry.size.width * 0.5)
                                    .overlay(
                                        VStack {
                                            Image(systemName: "video")
                                                .font(.system(size: 30))
                                                .foregroundColor(.white.opacity(0.6))
                                            Text("No thumbnail available")
                                                .font(.caption)
                                                .foregroundColor(.white.opacity(0.6))
                                        }
                                    )
                            }
                            
                            // Play button overlay (show if thumbnail is loaded or if we have video URL)
                            if (thumbnailLoaded || (refreshedVideoURL ?? memory.videoURL) != nil) && !isPlayingInline && !imageLoadError {
                                Button(action: {
                                    if let videoURLString = refreshedVideoURL ?? memory.videoURL,
                                       let videoURL = URL(string: videoURLString) {
                                        player = AVPlayer(url: videoURL)
                                        isPlayingInline = true
                                    }
                                }) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.white.opacity(0.3))
                                            .frame(width: 60, height: 60)
                                            .overlay(
                                                Circle()
                                                    .stroke(Color.white.opacity(0.5), lineWidth: 2)
                                            )
                                        
                                        Image(systemName: "play.fill")
                                            .font(.system(size: 24))
                                            .foregroundColor(.white)
                                            .offset(x: 3)
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            
                            // Fullscreen button (bottom right)
                            if ((thumbnailLoaded || (refreshedVideoURL ?? memory.videoURL) != nil) && !imageLoadError) || isPlayingInline {
                                VStack {
                                    Spacer()
                                    HStack {
                                        Spacer()
                                        Button(action: {
                                            showFullScreenVideo = true
                                        }) {
                                            Image(systemName: "arrow.up.left.and.arrow.down.right")
                                                .font(.system(size: 16))
                                                .foregroundColor(.white)
                                                .padding(8)
                                                .background(Color.black.opacity(0.5))
                                                .clipShape(RoundedRectangle(cornerRadius: 4))
                                        }
                                        .padding(12)
                                    }
                                }
                            }
                        }
                    )
                    .rotation3DEffect(
                        .degrees(motionManager.pitch * 20),
                        axis: (x: 1, y: 0, z: 0)
                    )
                    .rotation3DEffect(
                        .degrees(motionManager.roll * 20),
                        axis: (x: 0, y: 1, z: 0)
                    )
                    .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
            }
            .frame(width: geometry.size.width, height: geometry.size.width * 0.56)
            .animation(.easeOut(duration: 0.2), value: motionManager.roll)
            .animation(.easeOut(duration: 0.2), value: motionManager.pitch)
        }
    }
}
