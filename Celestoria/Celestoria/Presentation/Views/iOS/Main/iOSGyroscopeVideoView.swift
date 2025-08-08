//
//  iOSGyroscopeVideoView.swift
//  Celestoria-iOS
//
//  Created by Seyoung Park on 8/5/25.
//

import SwiftUI
import AVFoundation
import _AVKit_SwiftUI

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
                            // 재생 시작 시 동기화를 위해 약간의 지연 후 재생
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                player.play()
                            }
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
                            // 기존 플레이어가 있으면 재사용, 없으면 새로 생성
                            if player == nil {
                                player = AVPlayer(url: videoURL)
                            } else {
                                // 기존 플레이어의 URL이 다르면 새로 설정
                                if player?.currentItem?.asset as? AVURLAsset != AVURLAsset(url: videoURL) {
                                    player?.replaceCurrentItem(with: AVPlayerItem(url: videoURL))
                                }
                            }
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
