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
            Color.black
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Close button header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.white)
                            .padding(12)
                            .background(
                                Circle()
                                    .fill(Color.black.opacity(0.5))
                            )
                    }
                    .padding(.leading, 16)
                    .padding(.top, 8)
                    Spacer()
                }
                .zIndex(1)
                
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
                                HStack(spacing: 4) {
                                    Image(systemName: isLiked ? "heart.fill" : "heart")
                                        .font(.system(size: 18))
                                    Text("\(likeCount)")
                                        .font(.system(size: 16))
                                }
                                .foregroundColor(isLiked ? .red : .white)
                            }
                            .disabled(isLikeLoading || memory.userId == appState.userId)
                            
                            // Comment count
                            HStack(spacing: 4) {
                                Image(systemName: "message")
                                    .font(.system(size: 18))
                                Text("\(commentCount)")
                                    .font(.system(size: 16))
                            }
                            .foregroundColor(.white)
                            
                            Spacer()
                            
                            // Delete button (only for owner)
                            if memory.userId == appState.userId {
                                Button(action: {
                                    showDeleteConfirmation = true
                                }) {
                                    Image(systemName: "trash")
                                        .font(.system(size: 18))
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        
                        // Memory Info
                        VStack(alignment: .leading, spacing: 20) {
                            // Category and Date
                            HStack {
                                // Category
                                Text(memory.category.rawValue.uppercased())
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(Color(hex: "#7B61FF"))
                                
                                Text("•")
                                    .foregroundColor(.white.opacity(0.5))
                                
                                // Date
                                Text(formatDate(memory.createdAt))
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            
                            // Title
                            Text(memory.title)
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.white)
                            
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
        .confirmationDialog("Delete Memory Star", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                Task {
                    await deleteMemory()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this? This action cannot be undone.")
        }
        .task {
            await loadOwnerProfile()
            await loadLikeData()
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
    
    private func loadOwnerProfile() async {
        do {
            ownerProfile = try await diContainer.profileUseCase.fetchProfileByUserId(userId: memory.userId)
        } catch {
            print("Error loading owner profile: \(error)")
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "yyyy.MM.dd HH:mm"
        return displayFormatter.string(from: date)
    }
    
    private func deleteMemory() async {
        // TODO: Implement memory deletion
        // deleteMemoryUseCase is private in DIContainer
        dismiss()
    }
    
    private func loadLikeData() async {
        guard let currentUserId = appState.userId else { return }
        
        do {
            // Load like count and current user's like status
            async let likeCountResult = diContainer.memoryRepository.getLikeCount(for: memory.id)
            async let hasLikedResult = diContainer.memoryRepository.hasLiked(memoryId: memory.id, userId: currentUserId)
            
            let (count, liked) = try await (likeCountResult, hasLikedResult)
            
            likeCount = count
            isLiked = liked
        } catch {
            print("Error loading like data: \(error)")
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
}

// MARK: - Motion Manager
class MotionManager: ObservableObject {
    private let motionManager = CMMotionManager()
    @Published var pitch: Double = 0
    @Published var roll: Double = 0
    
    init() {
        if motionManager.isDeviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
            motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
                guard let motion = motion else { return }
                self?.pitch = motion.attitude.pitch
                self?.roll = motion.attitude.roll
            }
        }
    }
    
    deinit {
        motionManager.stopDeviceMotionUpdates()
    }
}

// MARK: - Gyroscope Video View
struct GyroscopeVideoView: View {
    let memory: Memory
    @Binding var isPlayingInline: Bool
    @Binding var showFullScreenVideo: Bool
    @Binding var player: AVPlayer?
    @ObservedObject var motionManager: MotionManager
    @State private var thumbnailLoaded = false
    
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
                            if let thumbnailURLString = memory.thumbnailURL,
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
                                    // Thumbnail
                                    AsyncImage(url: thumbnailURL) { image in
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: geometry.size.width * 0.9, height: geometry.size.width * 0.5)
                                            .clipShape(RoundedRectangle(cornerRadius: 20))
                                            .onAppear { thumbnailLoaded = true }
                                    } placeholder: {
                                        RoundedRectangle(cornerRadius: 20)
                                            .fill(Color.gray.opacity(0.3))
                                            .frame(width: geometry.size.width * 0.9, height: geometry.size.width * 0.5)
                                            .overlay(
                                                ProgressView()
                                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            )
                                    }
                                }
                            }
                            
                            // Play button overlay
                            if thumbnailLoaded && memory.videoURL != nil && !isPlayingInline {
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
                            }
                            
                            // Fullscreen button (bottom right)
                            if (thumbnailLoaded && memory.videoURL != nil) || isPlayingInline {
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