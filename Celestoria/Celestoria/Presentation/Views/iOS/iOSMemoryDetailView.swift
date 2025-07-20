//
//  iOSMemoryDetailView.swift
//  Celestoria
//
//  Created by Minjun Kim on 7/20/25.
//


import SwiftUI
import AVKit

struct iOSMemoryDetailView: View {
    let memory: Memory
    let diContainer: DIContainer
    @State private var showFullScreenVideo = false
    @State private var thumbnailLoaded = false
    @State private var ownerProfile: UserProfile?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.NebulaBlack
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Thumbnail Section with Play Button
                        if let thumbnailURLString = memory.thumbnailURL,
                           let thumbnailURL = URL(string: thumbnailURLString) {
                            ZStack {
                                AsyncImage(url: thumbnailURL) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(maxHeight: 300)
                                        .onAppear { thumbnailLoaded = true }
                                } placeholder: {
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(height: 300)
                                        .overlay(
                                            ProgressView()
                                        )
                                        .onAppear { thumbnailLoaded = false }
                                }
                                
                                // Play button overlay if video is available
                                if thumbnailLoaded && memory.videoURL != nil {
                                    Button(action: {
                                        showFullScreenVideo = true
                                    }) {
                                        ZStack {
                                            Circle()
                                                .fill(Color(hex: "E7E7E7").opacity(0.2))
                                                .frame(width: 60, height: 60)
                                            
                                            Image(systemName: "play.fill")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 25, height: 25)
                                                .foregroundColor(.white)
                                        }
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        } else {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 300)
                                .overlay(
                                    Text("No media available")
                                        .foregroundColor(.gray)
                                )
                        }
                        
                        // Memory Info
                        VStack(alignment: .leading, spacing: 16) {
                            // Title
                            Text(memory.title)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                            
                            // Category
                            HStack {
                                Image(memory.category.iconName)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 16, height: 16)
                                Text(memory.category.rawValue)
                                    .font(.system(size: 16))
                            }
                            .foregroundColor(memory.category.color)
                            
                            // Note
                            if !memory.note.isEmpty {
                                Text(memory.note)
                                    .font(.system(size: 16))
                                    .foregroundColor(.white.opacity(0.8))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            
                            // Owner Info
                            if let profile = ownerProfile {
                                HStack(spacing: 12) {
                                    AsyncImage(url: URL(string: profile.profileImageURL ?? "")) { image in
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                    } placeholder: {
                                        Circle()
                                            .fill(Color.gray)
                                    }
                                    .frame(width: 40, height: 40)
                                    .clipShape(Circle())
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(profile.name)
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.white)
                                        Text("Owner")
                                            .font(.system(size: 12))
                                            .foregroundColor(.white.opacity(0.6))
                                    }
                                    
                                    Spacer()
                                }
                                .padding(.top, 8)
                            }
                            
                            // Date
                            Text(formatDate(memory.createdAt))
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.6))
                                .padding(.top, 8)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .task {
            await loadOwnerProfile()
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
        displayFormatter.dateStyle = .medium
        displayFormatter.timeStyle = .short
        return displayFormatter.string(from: date)
    }
}

