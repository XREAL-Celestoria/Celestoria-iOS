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
    @State private var isPlayingInline = false
    @State private var player: AVPlayer?
    @StateObject private var motionManager = MotionManager()
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    // State for data loading
    @State private var userProfile: UserProfile?
    @State private var likeCount: Int = 0
    @State private var isLiked: Bool = false
    @State private var isLikeLoading: Bool = false
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    
    // Delete confirmation
    @State private var showDeleteAlert: Bool = false
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd HH:mm"
        return formatter.string(from: memory.createdAt)
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
                            
                            // Comment count (placeholder)
                            HStack(spacing: 8) {
                                Image("commentWhiteIcon")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 24, height: 24)
                                
                                Text("0") // Placeholder
                                    .fontStyle(Fonts.caption1)
                                    .foregroundStyle(Colors.NebulaWhite)
                            }
                            
                            Spacer()
                            
                            // Delete button (only for owner)
                            if memory.userId == appState.userId {
                                Button(action: {
                                    showDeleteAlert = true
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
                            // Date
                            Text(formattedDate)
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
                            if let profile = userProfile {
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
            
            // Loading indicator
            if isLoading {
                ProgressView("Loading...")
                    .frame(width: 120, height: 120)
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(12)
                    .foregroundColor(.white)
            }
            
            // Error message
            if let errorMessage = errorMessage {
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
                        self.errorMessage = nil
                }
            }
        }
        .navigationBarHidden(true)
        .task {
            await loadData()
        }
        .alert("Delete Memory Star", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                            Task {
                    await deleteMemory()
                }
            }
        } message: {
            Text("Are you sure you want to delete this memory? This action cannot be undone.")
        }
        .fullScreenCover(isPresented: $showFullScreenVideo) {
            if let videoURLString = memory.videoURL,
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
    
    // MARK: - Data Loading
    private func loadData() async {
        isLoading = true
        defer { isLoading = false }
        
        // Load all data in parallel
        async let profileTask = loadUserProfile()
        async let likeDataTask = loadLikeData()
        
        await profileTask
        await likeDataTask
    }
    
    private func loadUserProfile() async {
        do {
            let profile = try await diContainer.profileUseCase.fetchProfileByUserId(userId: memory.userId)
            await MainActor.run {
                self.userProfile = profile
            }
        } catch {
            print("Error loading user profile: \(error)")
            await MainActor.run {
                self.errorMessage = "Failed to load user profile"
            }
        }
    }
    
    private func loadLikeData() async {
        guard let currentUserId = appState.userId else { return }
        
        do {
            // Load like count and current user's like status
            async let likeCountResult = diContainer.memoryRepository.getLikeCount(for: memory.id)
            async let hasLikedResult = diContainer.memoryRepository.hasLiked(memoryId: memory.id, userId: currentUserId)
            
            let (count, liked) = try await (likeCountResult, hasLikedResult)
            
            await MainActor.run {
                self.likeCount = count
                self.isLiked = liked
            }
        } catch {
            print("Error loading like data: \(error)")
        }
    }
    
    // MARK: - Like Toggle
    private func toggleLike() async {
        guard let currentUserId = appState.userId else { return }
        guard !isLikeLoading else { return }
        
        // Check if user is trying to like their own memory
        if memory.userId == currentUserId {
            await MainActor.run {
                self.errorMessage = "자신의 메모리에는 좋아요를 할 수 없습니다."
            }
            return
        }
        
        await MainActor.run {
            self.isLikeLoading = true
        }
        defer {
            Task { @MainActor in
                self.isLikeLoading = false
            }
        }
        
        do {
            if isLiked {
                // Unlike
                try await diContainer.memoryRepository.deleteLike(memoryId: memory.id, userId: currentUserId)
                await MainActor.run {
                    self.likeCount = max(0, self.likeCount - 1)
                    self.isLiked = false
                }
            } else {
                // Like
                try await diContainer.memoryRepository.createLike(memoryId: memory.id, userId: currentUserId)
                await MainActor.run {
                    self.likeCount += 1
                    self.isLiked = true
                }
            }
        } catch {
            print("Error toggling like: \(error)")
            await MainActor.run {
                self.errorMessage = "좋아요 처리 중 오류가 발생했습니다."
            }
        }
    }
    
    // MARK: - Delete Memory
    private func deleteMemory() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Extract paths from URLs for file deletion
            let videoPath = extractPathFromURL(memory.videoURL)
            let thumbnailPath = extractPathFromURL(memory.thumbnailURL)
            
            // Delete memory using UseCase
            try await diContainer.deleteMemoryUseCase.execute(
                memoryId: memory.id,
                videoPath: videoPath,
                thumbnailPath: thumbnailPath
            )
            
            // Refresh main view and dismiss
            await MainActor.run {
                appState.refreshMainView = true
                dismiss()
            }
            
        } catch {
            print("Error deleting memory: \(error)")
            await MainActor.run {
                self.errorMessage = "메모리 삭제 중 오류가 발생했습니다."
            }
        }
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
}

// MARK: - Gyroscope Video View (Simplified)
struct GyroscopeVideoView: View {
    let memory: Memory
    @Binding var isPlayingInline: Bool
    @Binding var showFullScreenVideo: Bool
    @Binding var player: AVPlayer?
    @ObservedObject var motionManager: MotionManager
    @State private var thumbnailLoaded = false
    @State private var imageLoadError = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Main content - exactly like visionOS structure
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
                } else if let thumbnailURL = URL(string: memory.thumbnailURL ?? "") {
                    // AsyncImage - EXACTLY like visionOS (no complex overlay structure)
                    AsyncImage(url: thumbnailURL) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .frame(width: 44, height: 44)
                                .frame(width: geometry.size.width * 0.9, height: geometry.size.width * 0.5)
                                .background(Color.gray.opacity(0.3))
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                                .onAppear { 
                                    thumbnailLoaded = false 
                                    print("🔄 DEBUG: Loading thumbnail: \(thumbnailURL)")
                                }
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: geometry.size.width * 0.9, height: geometry.size.width * 0.5)
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                                .onAppear { 
                                    thumbnailLoaded = true 
                                    imageLoadError = false
                                    print("✅ DEBUG: Thumbnail loaded successfully")
                                }
                        case .failure(let error):
                            Color.gray
                                .opacity(0.3)
                                .frame(width: geometry.size.width * 0.9, height: geometry.size.width * 0.5)
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                                .onAppear {
                                    imageLoadError = true
                                    print("❌ DEBUG: AsyncImage failed to load: \(error)")
                                    print("❌ DEBUG: Failed URL: \(thumbnailURL)")
                                }
                        @unknown default:
                            Color.gray.opacity(0.3)
                                .frame(width: geometry.size.width * 0.9, height: geometry.size.width * 0.5)
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                        }
                    }
            } else {
                    // No thumbnail URL available
                    Color.gray.opacity(0.3)
                        .frame(width: geometry.size.width * 0.9, height: geometry.size.width * 0.5)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
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
                
                // Play button overlay - positioned like visionOS
                if (thumbnailLoaded || memory.videoURL != nil) && !isPlayingInline && !imageLoadError {
                    Button(action: {
                        if let videoURLString = memory.videoURL,
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
                    .position(x: geometry.size.width / 2, y: geometry.size.width * 0.28)
                }
                
                // Fullscreen button (bottom right)
                if ((thumbnailLoaded || memory.videoURL != nil) && !imageLoadError) || isPlayingInline {
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
                    .position(x: geometry.size.width * 0.85, y: geometry.size.width * 0.45)
                }
            }
            // Apply gyroscope effect to the entire ZStack
            .rotation3DEffect(
                .degrees(motionManager.pitch * 20),
                axis: (x: 1, y: 0, z: 0)
            )
            .rotation3DEffect(
                .degrees(motionManager.roll * 20),
                axis: (x: 0, y: 1, z: 0)
            )
            .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
            .frame(width: geometry.size.width, height: geometry.size.width * 0.56)
            .animation(.easeOut(duration: 0.2), value: motionManager.roll)
            .animation(.easeOut(duration: 0.2), value: motionManager.pitch)
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