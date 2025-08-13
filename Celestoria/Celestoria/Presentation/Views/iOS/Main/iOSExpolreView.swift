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
                                    if !viewModel.isCurrentUser(user) {
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
                                            if !viewModel.isCurrentUser(user) {
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
                                    if !viewModel.isCurrentUser(user) {
                                        viewModel.selectedUser = user
                                        viewModel.showingUserSpace = true
                                    }
                                }) {
                                    LatestExploreItemView(card: card, user: user)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .onAppear {
                                    if index == viewModel.latestUsers.count - 1 {
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
            
            .task {
                await viewModel.fetchMostStarsUsers()
                await viewModel.fetchPopularUsers()
                await viewModel.fetchLatestUsers()
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
            // Removed own-galaxy popup sheet
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
