//
//  iOSExpolreView.swift
//  Celestoria
//
//  Created by Seyoung Park on 8/12/25.
//

import SwiftUI
import Foundation

struct iOSExploreView: View {
    @StateObject private var viewModel: ExploreViewModel
    @EnvironmentObject private var appState: AppState
    @Binding var showingSearchView: Bool
    @State private var showingOwnGalaxyPopup = false
    
    private let columns: [GridItem] = [
        GridItem(.flexible(), spacing: 12)
    ]
    
    init(diContainer: DIContainer, showingSearchView: Binding<Bool>) {
        _viewModel = StateObject(wrappedValue: diContainer.makeExploreViewModel())
        self._showingSearchView = showingSearchView
    }
    
    var body: some View {
        ZStack {
            Colors.backgroundMain.ignoresSafeArea()
            
            contentView
            
            .task {
                await viewModel.loadInitialExploreData()
            }
            .fullScreenCover(isPresented: $viewModel.showingUserSpace) {
                if let selectedUser = viewModel.selectedUser {
                    iOS3DGalaxyView(diContainer: viewModel.diContainer, targetUserId: selectedUser.profile.userId)
                        .transition(.move(edge: .trailing))
                }
            }
            .fullScreenCover(isPresented: $showingSearchView) {
                iOSExploreSearchView(viewModel: viewModel, onClose: { showingSearchView = false })
                    .toolbar(.hidden, for: .navigationBar)
            }
        }
        .overlay(
            Group {
                // 자기 갤럭시 팝업 (조건부 렌더링)
                if showingOwnGalaxyPopup {
                    iOSConfirmationPopupView(
                        title: "Your Own Galaxy",
                        message: "This is your own galaxy. You can view it from the main screen.",
                        style: .singleButton(title: "OK"),
                        onCancel: { 
                            withAnimation(.easeInOut(duration: 0.4)) {
                                showingOwnGalaxyPopup = false
                            }
                        },
                        onConfirm: { 
                            withAnimation(.easeInOut(duration: 0.4)) {
                                showingOwnGalaxyPopup = false
                            }
                        }
                    )
                    .transition(.asymmetric(
                        insertion: .opacity.animation(.easeInOut(duration: 0.4)),
                        removal: .opacity.animation(.easeInOut(duration: 0.4))
                    ))
                }
            }
        )
    }
    
    // MARK: - Content View
    private var contentView: some View {
        ZStack {
            // 항상 콘텐츠 표시 (로딩 중에도 배경으로)
            exploreListView
                .opacity(viewModel.isInitialLoading ? 0.3 : 1.0)
                .animation(.easeInOut(duration: 0.3), value: viewModel.isInitialLoading)
            
            // 로딩 오버레이
            if viewModel.isInitialLoading {
                iOSUnifiedLoadingView(title: "Loading Explore...")
                    .transition(.opacity.animation(.easeInOut(duration: 0.5)))
            }
        }
    }
    
    private var exploreListView: some View {
        ScrollView {
            VStack(alignment: .leading) {
                Spacer().frame(height: 30)
                
                //Most Stars
                Text("Most Stars")
                    .fontStyle(Fonts.title3)
                    .foregroundStyle(Colors.NebulaWhite)
                    .padding(.horizontal, 24)
                
                Spacer().frame(height: 20)
                
                LazyVGrid(columns: columns, spacing: 40) {
                    let topUsers = Array(viewModel.mostStarsUsers.prefix(3))
                    ForEach(Array(topUsers.enumerated()), id: \.offset) { index, user in
                        if let card = viewModel.getCardItem(by: user.profile.userId) {
                            Button(action: {
                                if viewModel.isCurrentUser(user) {
                                    // 자기 자신의 갤럭시를 누를 때
                                    showingOwnGalaxyPopup = true
                                } else {
                                    // 다른 유저의 갤럭시를 누를 때
                                    viewModel.selectedUser = user
                                    viewModel.showingUserSpace = true
                                }
                            }) {
                                RankedExploreItemView(rank: index + 1, card: card, user: user)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                .padding(.horizontal, 16)
                
                Spacer().frame(height: 64)
                
                // Popular
                if !viewModel.popularUsers.isEmpty {
                    Text("Popular")
                        .fontStyle(Fonts.title3)
                        .foregroundStyle(Colors.NebulaWhite)
                        .padding(.horizontal, 24)
                    
                    Spacer().frame(height: 20)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 28) {
                            ForEach(Array(viewModel.popularUsers.enumerated()), id: \.offset) { index, user in
                                if let card = viewModel.getCardItem(by: user.profile.userId) {
                                    Button(action: {
                                        if viewModel.isCurrentUser(user) {
                                            // 자기 자신의 갤럭시를 누를 때
                                            showingOwnGalaxyPopup = true
                                        } else {
                                            // 다른 유저의 갤럭시를 누를 때
                                            viewModel.selectedUser = user
                                            viewModel.showingUserSpace = true
                                        }
                                    }) {
                                        PopularExploreItemView(card: card, rank: index + 1, user: user)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                }
                
                Spacer().frame(height: 64)
                
                // Latest
                Text("Latest")
                    .fontStyle(Fonts.title3)
                    .foregroundStyle(Colors.NebulaWhite)
                    .padding(.horizontal, 24)
                
                Spacer().frame(height: 20)
                
                LazyVGrid(columns: columns, spacing: 40) {
                    ForEach(viewModel.latestUsers, id: \.profile.userId) { user in
                        if let card = viewModel.getCardItem(by: user.profile.userId) {
                            let index = viewModel.latestUsers.firstIndex(where: { $0.profile.userId == user.profile.userId }) ?? 0
                            Button(action: {
                                if viewModel.isCurrentUser(user) {
                                    // 자기 자신의 갤럭시를 누를 때
                                    showingOwnGalaxyPopup = true
                                } else {
                                    // 다른 유저의 갤럭시를 누를 때
                                    viewModel.selectedUser = user
                                    viewModel.showingUserSpace = true
                                }
                            }) {
                                LatestExploreItemView(card: card, user: user)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .onAppear {
                                // 마지막 아이템이 보일 때 더 많은 데이터 로드
                                if index == viewModel.latestUsers.count - 1 && !viewModel.isLoadingLatestUsers {
                                    Task {
                                        await viewModel.loadMoreLatestUsers()
                                    }
                                }
                            }
                        }
                    }
                    
                    if viewModel.isLoadingLatestUsers {
                        HStack {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: Colors.NebulaWhite))
                                .scaleEffect(1.2)
                            Text("Loading more...")
                                .fontStyle(Fonts.caption1)
                                .foregroundStyle(Colors.NebulaWhite)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.bottom, 24)
        }
    }
    
    // MARK: - Ranked Explore Item View
    private struct RankedExploreItemView: View {
        let rank: Int
        let card: ExploreUserCardItem
        let user: ExploreUser
        
        private var rankImageName: String { "rankImage\(rank)" }
        
        var body: some View {
            VStack(alignment: .leading, spacing: 10) {
                Image(rankImageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                
                HStack(alignment: .top, spacing: 12) {
                    Image(card.imageName)
                        .resizable()
                        .scaledToFill()
                        .frame(
                            width: UIScreen.main.bounds.width * 0.61,
                            height: UIScreen.main.bounds.width * 0.61 * (152.0 / 240.0)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 30))
                        .overlay(
                            RoundedRectangle(cornerRadius: 30)
                                .stroke(LinearGradient.SearchUsercardBG, lineWidth: 5)
                        )
                    
                    VStack(alignment: .leading, spacing: 8) {
                        ProfileImageView(
                            profile: user.profile,
                            size: 32
                        )
                        
                        Text(card.userName)
                            .fontStyle(Fonts.subheadline)
                            .foregroundStyle(Colors.NebulaWhite)
                        
                        Text("\(card.memoryStars) Memory Stars")
                            .fontStyle(Fonts.caption2)
                            .foregroundStyle(Colors.Placeholder)
                    }
                }
            }
        }
    }
    
    // MARK: - Popular Explore Item View
    private struct PopularExploreItemView: View {
        let card: ExploreUserCardItem
        let rank: Int
        let user: ExploreUser
        
        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                
                Spacer().frame(height: 2)
                
                Image(card.imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(
                        width: UIScreen.main.bounds.width * 0.57,
                        height: UIScreen.main.bounds.width * 0.57 * (300.0 / 224.0)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 30))
                    .overlay(
                        RoundedRectangle(cornerRadius: 30)
                            .stroke(LinearGradient.SearchUsercardBG, lineWidth: 5)
                    )
                
                HStack(spacing: 8) {
                    // Profile image
                    ProfileImageView(
                        profile: user.profile,
                        size: 32
                    )
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(card.userName)
                            .fontStyle(Fonts.subheadline)
                            .foregroundStyle(Colors.NebulaWhite)
                            .lineLimit(1)
                        
                        Text("\(card.memoryStars) Memory Stars")
                            .fontStyle(Fonts.caption2)
                            .foregroundStyle(Colors.Placeholder)
                    }
                }
            }
        }
    }
}
    
    // MARK: - Latest Explore Item View
    private struct LatestExploreItemView: View {
        let card: ExploreUserCardItem
        let user: ExploreUser
        
        var body: some View {
            HStack(alignment: .top, spacing: 12) {
                Image(card.imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(
                        width: UIScreen.main.bounds.width * 0.61,
                        height: UIScreen.main.bounds.width * 0.61 * (152.0 / 240.0)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 30))
                    .overlay(
                        RoundedRectangle(cornerRadius: 30)
                            .stroke(LinearGradient.SearchUsercardBG, lineWidth: 5)
                    )
                
                VStack(alignment: .leading, spacing: 8) {
                    ProfileImageView(
                        profile: user.profile,
                        size: 32
                    )
                    
                    Text(card.userName)
                        .fontStyle(Fonts.subheadline)
                        .foregroundStyle(Colors.NebulaWhite)
                    
                    Text("\(card.memoryStars) Memory Stars")
                        .fontStyle(Fonts.caption2)
                        .foregroundStyle(Colors.Placeholder)
                }
            }
        }
    }
