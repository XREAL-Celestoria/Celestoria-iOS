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
    @Environment(\.dismissWindow) private var dismissWindow
    @State private var showFullScreenVideo: Bool = false
    @State private var thumbnailLoaded: Bool = false
    
    init(memory: Memory, memoryRepository: MemoryRepository, profileUseCase: ProfileUseCase) {
        _viewModel = StateObject(wrappedValue: MemoryDetailViewModel(
            memory: memory,
            memoryRepository: memoryRepository,
            profileUseCase: profileUseCase
        ))
    }
    
    var body: some View {
        GradientBorderContainer {
            ZStack {
                GeometryReader { geometry in
                    thumbnailImageSection(geometry: geometry)
                    
                    VStack {
                        NavigationBarWithMenu(
                            title: "Memory Detail",
                            leftAction: {
                                dismissWindow(id: "Memory-Detail")
                            },
                            leftButtonImageString: "xmark",
                            reportAction: {
                                // Report Post 버튼 액션 구현
                                print("Report Post tapped")
                            },
                            blockAction: {
                                // Block User 버튼 액션 구현
                                print("Block User tapped")
                            }
                        )
                        .padding(.horizontal, 28)
                        .padding(.top, 28)
                        
                        Spacer()
                        
                        MemoryInfoView(viewModel: viewModel, spaceCoordinator: _spaceCoordinator)
                            .frame(width: geometry.size.width, height: geometry.size.height * 0.4)
                            .padding(.bottom, 0)
                    }
                }
                
                if viewModel.isLoading || viewModel.isDeleting {
                    ProgressView("Loading...")
                        .frame(width: 120, height: 120)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(12)
                        .foregroundColor(.white)
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
    }
    
    @ViewBuilder
    private func thumbnailImageSection(geometry: GeometryProxy) -> some View {
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
                        
                        
                        CircularButton(action: {
                            os.Logger.info("Playing")
                            showFullScreenVideo = true
                        }, buttonImageString: "play.fill")
                        .frame(width: 60, height: 60)
                        .position(x: geometry.size.width / 2, y: (geometry.size.height * 0.72) / 2)
                        
                        
                    }
                case .failure:
                    Color.gray
                        .opacity(0.3)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                @unknown default:
                    EmptyView()
                }
            }
        } else {
            Color.gray.opacity(0.3)
        }
    }
}

struct MemoryInfoView: View {
    @ObservedObject var viewModel: MemoryDetailViewModel
    @Environment(\.dismissWindow) private var dismissWindow
    @EnvironmentObject var spaceCoordinator: SpaceCoordinator
    @EnvironmentObject var appModel: AppModel
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            VisualEffectBlur(style: .systemMaterial)
                .edgesIgnoringSafeArea(.all)
            
            Rectangle()
                .fill(Color.clear)
                .overlay(
                    Color.NebulaBlack.opacity(0.3)
                        .shadow(.inner(color: Color.NebulaWhite.opacity(0.8), radius: 24))
                )
                .edgesIgnoringSafeArea(.all)
            
            HStack(alignment: .top) {
                profileImageSection
                    .padding(.leading, 60)
                    .padding(.top, 28)
                
                Spacer()
                
                VStack(alignment: .leading) {
                    HStack {
//                        Text("Seoul")
//                            .foregroundColor(.NebulaWhite)
//                            .font(.system(size: 12, weight: .medium))
//                        Circle()
//                            .fill(Color.NebulaWhite.opacity(0.6))
//                            .frame(width: 4, height: 4)
//                            .padding(.leading, 8)
                        
                        Text(viewModel.formattedDate)
                            .foregroundColor(.NebulaWhite)
                            .font(.system(size: 12, weight: .medium))
//                            .padding(.leading, 8)
                        
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
            
            if let currentUserId = appModel.userId,
               currentUserId == viewModel.memory.userId {
                Button(action: {
                    viewModel.showDeletePopup(
                        dismissWindow: {
                            dismissWindow(id: "Memory-Detail")
                        },
                        onMemoryDeleted: { deletedMemory in
                            Task {
                                await spaceCoordinator.loadData(for: currentUserId)
                            }
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

    // MARK: - 프로필 이미지 섹션
    @ViewBuilder
    private var profileImageSection: some View {
        if let userProfile = viewModel.userProfile,
           let urlString = userProfile.profileImageURL,
           let url = URL(string: urlString) {
            
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(width: 24, height: 24)
                case .success(let image):
                    image
                        .resizable()
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
            // 프로필이 없거나 URL이 없으면 기본 이미지
            Image("CardUserProfileImage")
                .resizable()
                .scaledToFill()
                .frame(width: 52, height: 52)
                .clipShape(Circle())
        }
    }
}
