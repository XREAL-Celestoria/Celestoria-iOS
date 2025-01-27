//
//  MemoryDetailView.swift
//  Celestoria
//
//  Created by Park Seyoung on 1/22/25.
//

import SwiftUI
import os
import AVKit

struct MemoryDetailView: View {
    @StateObject private var viewModel: MemoryDetailViewModel
    @Environment(\.dismissWindow) private var dismissWindow
    @State private var isHovered: Bool = false
    @State private var showFullScreenVideo: Bool = false
    @State private var thumbnailLoaded: Bool = false
    
    init(memory: Memory) {
        _viewModel = StateObject(wrappedValue: MemoryDetailViewModel(memory: memory))
    }
    
    var body: some View {
        GradientBorderContainer {
            ZStack {
                GeometryReader { geometry in
                    thumbnailImageSection(geometry: geometry, isHovered: isHovered)
                        .onHover { isHovering in
                            withAnimation {
                                isHovered = isHovering
                            }
                        }
                    
                    VStack {
                        NavigationBar(
                            title: "Memory Detail",
                            action: {
                                dismissWindow(id: "Memory-Detail")
                            },
                            buttonImageString: "xmark"
                        )
                        .padding(.horizontal, 28)
                        .padding(.top, 28)
                        
                        Spacer()
                        
                        MemoryInfoView(viewModel: viewModel)
                            .frame(width: geometry.size.width, height: geometry.size.height * 0.4)
                            .padding(.bottom, 0)
                    }
                }
            }
            .fullScreenCover(isPresented: $showFullScreenVideo) {
                if let videoURL = viewModel.memory.videoURL, let url = URL(string: videoURL) {
                    CelestoriaVideoPlayerView(videoURL: url)
                        .edgesIgnoringSafeArea(.all)
                        .background(Color.black)
                        .onTapGesture {
                            showFullScreenVideo = false
                        }
                } else {
                    Text("Video not available")
                        .font(.title)
                        .foregroundColor(.white)
                        .background(Color.black)
                        .edgesIgnoringSafeArea(.all)
                }
            }
        }
    }
    
    @ViewBuilder
    private func thumbnailImageSection(geometry: GeometryProxy, isHovered: Bool) -> some View {
        if let thumbnailURL = URL(string: viewModel.memory.thumbnailURL ?? "") {
            AsyncImage(url: thumbnailURL) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(width: 44, height: 44)
                        .position(x: geometry.size.width / 2, y: (geometry.size.height * 0.72) / 2)
                        .onAppear {
                            thumbnailLoaded = false
                        }
                case .success(let image):
                    ZStack {
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .overlay(Color.NebulaBlack.opacity(0.6))
                            .onAppear {
                                thumbnailLoaded = true
                            }
                        
                        if isHovered {
                            CircularButton(action: {
                                os.Logger.info("Playing")
                                showFullScreenVideo = true
                            }, buttonImageString: "play.fill")
                            .frame(width: 60, height: 60)
                            .position(x: geometry.size.width / 2, y: (geometry.size.height * 0.72) / 2)
                            .opacity(isHovered ? 1 : 0)
                        }
                    }
                case .failure:
                    ZStack {
                        Image(systemName: "Thumbnail1")
                            .resizable()
                            .scaledToFit()
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .overlay(Color.NebulaBlack.opacity(0.6))
                            .onAppear {
                                thumbnailLoaded = true
                            }
                        if isHovered {
                            CircularButton(action: {
                                os.Logger.info("Playing")
                                showFullScreenVideo = true
                            }, buttonImageString: "play.fill")
                            .frame(width: 60, height: 60)
                            .position(x: geometry.size.width / 2, y: (geometry.size.height * 0.72) / 2)
                            .opacity(isHovered ? 1 : 0)
                        }
                    }
                    
                @unknown default:
                    EmptyView()
                }
            }
        } else {
            Color.gray.opacity(0.3)
                .frame(width: geometry.size.width, height: geometry.size.height)
                .onAppear {
                    thumbnailLoaded = false
                }
        }
    }
}


struct MemoryInfoView: View {
    @ObservedObject var viewModel: MemoryDetailViewModel
    
    var body: some View {
        ZStack(alignment: .topTrailing) { // ZStack에 alignment 지정
            VisualEffectBlur(style: .systemMaterial)
                .edgesIgnoringSafeArea(.all)
            
            Rectangle()
                .fill(Color.clear)
                .overlay(
                    Color.NebulaBlack.opacity(0.3)
                        .shadow(.inner(color: Color.NebulaWhite.opacity(0.8), radius: 24))
                )
                .edgesIgnoringSafeArea(.all)
            
            // HStack으로 메인 콘텐츠 구성
            HStack(alignment: .top) {
                Image("CardUserProfileImage")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 52, height: 52, alignment: .leading)
                    .padding(.leading, 60)
                    .padding(.top, 28)
                
                Spacer()
                
                VStack(alignment: .leading) {
                    HStack {
                        Text("Seoul")
                            .foregroundColor(.NebulaWhite)
                            .font(.system(size: 12, weight: .medium))
                        
                        Circle()
                            .fill(Color.NebulaWhite.opacity(0.6))
                            .frame(width: 4, height: 4)
                            .padding(.leading, 8)
                        
                        Text(viewModel.formattedDate)
                            .foregroundColor(.NebulaWhite)
                            .font(.system(size: 12, weight: .medium))
                            .padding(.leading, 8)
                        
                        Spacer()
                    }
                    Text(viewModel.memory.title)
                        .foregroundColor(.NebulaWhite)
                        .font(.system(size: 24, weight: .bold))
                        .padding(.top, 0)
                    
                    Text(viewModel.memory.note)
                        .foregroundColor(.white)
                        .font(.system(size: 14, weight: .medium))
                        .frame(maxWidth: 1075, alignment: .topLeading)
                        .padding(.top, 8)
                    
                    Spacer()
                }
                .padding(.leading, 8)
                .padding(.top, 28)
            }
            
            Button(action: {
                os.Logger.info("Memory Delete...")
            }
            ) {
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

