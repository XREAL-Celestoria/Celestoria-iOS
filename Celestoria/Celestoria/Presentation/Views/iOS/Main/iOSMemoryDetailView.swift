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
    @StateObject private var motionManager = MotionManager()
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    init(memory: Memory, diContainer: DIContainer) {
        self.memory = memory
        self.diContainer = diContainer
        _viewModel = StateObject(wrappedValue: iOSMemoryDetailViewModel(
            memory: memory,
            diContainer: diContainer
        ))
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
                                    await viewModel.toggleLike()
                                }
                            }) {
                                HStack(spacing: 8) {
                                    Image(viewModel.isLiked ? "likeWhiteIcon" : "likeWhiteIcon")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 24, height: 24)
                                    
                                    Text("\(viewModel.likeCount)")
                                        .fontStyle(Fonts.caption1)
                                        .foregroundStyle(Colors.NebulaWhite)
                                }
                            }
                            .disabled(!viewModel.canLike)
                            
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
                        
                        // Memory Info
                        VStack(alignment: .leading) {
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
            viewModel.setup(appState: appState)
        }
        .task {
            await viewModel.loadData()
        }
        .alert("Delete Memory Star", isPresented: $viewModel.showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    let success = await viewModel.deleteMemory()
                    if success {
                        dismiss()
                    }
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
}
