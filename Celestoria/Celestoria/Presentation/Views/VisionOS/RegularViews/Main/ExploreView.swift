//
//  ExploreView.swift
//  Celestoria
//
//  Created by Park Seyoung on 1/20/25.
//

import SwiftUI
import os

struct ExploreView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject var spaceCoordinator: SpaceCoordinator
    @EnvironmentObject var exploreViewModel: ExploreViewModel

    @Environment(\.dismissWindow) private var dismissWindow
    @Environment(\.openWindow) private var openWindow
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace

    @FocusState private var isSearchFieldFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // NavigationBar
                NavigationBar(
                    title: "Explore",
                    action: {
                        appState.activeScreen = .main
                    },
                    buttonImageString: "chevron.left"
                )
                .padding(.horizontal, 28)
                .padding(.top, 16)

                if exploreViewModel.isLoading {
                    // 로딩 중 표시
                    ProgressView()
                        .scaleEffect(1.5)
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .padding(.top, 50)
                    
                } else if exploreViewModel.exploreUsers.isEmpty {
                    // 검색 결과 없음 (검색어 없으면 "모두 불러오기" + 0명일 경우 대비)
                    // or 검색 결과가 0명일 때
                    Image("AddMemoryDone")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 320, height: 320, alignment: .center)
                        .padding(.top, 64)

                    Text("Explore other people's Galaxy!")
                        .foregroundColor(Colors.NebulaWhite)
                        .font(.system(size: 22, weight: .bold))
                        .padding(.top, 32)
                    
                } else {
                    // 유저 카드 목록
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 20) {
                            ForEach(exploreViewModel.exploreUsers, id: \.profile.id) { user in
                                if let cardItem = exploreViewModel.getCardItem(by: user.profile.userId) {
                                    ExploreUserCard(
                                        item: cardItem,
                                        onExploreGalaxy: {
                                            guard !appState.showExploreNavigatorView else {
                                                os.Logger.info("Explore Navigator View is already opened")
                                                return
                                            }
                                            
                                            os.Logger.info("Displaying Explore Navigator View")
                                            appState.showExploreNavigatorView = true
                                            openWindow(value: user.profile.userId)
                                            dismissWindow()
                                        }
                                    )
                                }
                            }
                        }
                        .padding(.horizontal, 48)
                    }
                    .padding(.top, 44)
                }

                Spacer()
            }
            .overlay(loadingOverlay)
            .toolbar {
                ToolbarItem(placement: .bottomOrnament) {
                    ZStack {
                        // Toolbar Background
                        RoundedRectangle(cornerRadius: 42)
                            .fill(LinearGradient.GradientMain)
                            .frame(width: 920, height: 84)

                        HStack {
                            // Search Bar Background
                            ZStack {
                                RoundedRectangle(cornerRadius: 28)
                                    .fill(Colors.NebulaBlack)
                                    .frame(width: 832, height: 56)
                                    .padding(.leading, 16)

                                HStack {
                                    Image("Explore")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 24, height: 24)
                                        .padding(.leading, 36)

                                    ZStack(alignment: .leading) {
                                        if exploreViewModel.searchText.isEmpty {
                                            Text("Search user name")
                                                .foregroundColor(Colors.NebulaWhite)
                                                .font(.system(size: 16))
                                                .padding(.leading, 8)
                                        }
                                        
                                        TextField("", text: $exploreViewModel.searchText)
                                            .submitLabel(.search)
                                            .foregroundColor(Colors.NebulaWhite)
                                            .font(.system(size: 16))
                                            .tint(Colors.NebulaWhite)
                                            .focused($isSearchFieldFocused)
                                            .onSubmit {
                                                Task {
                                                    await exploreViewModel.fetchExploreUsers()
                                                }
                                            }
                                            .padding(.leading, 8)
                                    }

                                    Spacer()
                                }
                                .padding(.horizontal, 16)
                            }

                            Spacer()

                            Button(action: {
                                exploreViewModel.searchText = ""
                                exploreViewModel.onChangeSearchText()
                            }) {
                                Image("Close")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 24, height: 24)
                                    .foregroundColor(.gray)
                            }
                            .frame(width: 44, height: 44)
                            .buttonStyle(.plain)
                            .padding(.trailing, 20)
                        }
                    }
                    .padding(.horizontal, -16)
                    .padding(.vertical, -16)
                }
            }
            .onAppear {
                // 화면 진입 시 한번 불러오기
                Task {
                    await exploreViewModel.fetchExploreUsers()
                }
            }
        }
        .onChange(of: scenePhase) { newPhase in
            switch newPhase {
            case .background, .inactive:
                appState.isImmersiveViewActive = false
            case .active:
                if appState.userId != nil && !appState.isImmersiveViewActive {
                    Task {
                        await openImmersiveSpace(id: appState.immersiveSpaceID)
                        appState.isImmersiveViewActive = true
                    }
                }
            default:
                break
            }
        }
    }
    
    // MARK: - Subviews
    private var loadingOverlay: some View {
        Group {
            if spaceCoordinator.isLoading {
                ZStack {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                    ProgressView("Loading Stars...")
                        .scaleEffect(1.5)
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .zIndex(1)
                }
            }
            
            if let errorMessage = exploreViewModel.errorMessage {
                ErrorBannerView(message: errorMessage) {
                    exploreViewModel.errorMessage = nil
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .zIndex(1)
            }
        }
    }
}

struct ExploreUserCard: View {
    let item: ExploreUserCardItem

    /// 버튼 액션을 부모가 주입할 수 있게 클로저 추가
    let onExploreGalaxy: () -> Void

    var body: some View {
        VStack {
            Spacer()
                .frame(height: 16)
            
            ZStack {
                Image(item.imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 400, height: 420)
                    .cornerRadius(16)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                LinearGradient(
                    gradient: Gradient(colors: [Color.black.opacity(0.7), Color.clear]),
                    startPoint: .bottom,
                    endPoint: .top
                )
                .frame(width: 400, height: 100)
                .cornerRadius(16)
                .padding(.top, 320)

                VStack {
                    HStack {
                        if item.isCustomImage, let url = URL(string: item.userProfileImageName) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .empty:
                                    ProgressView()
                                        .frame(width: 32, height: 32)
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 32, height: 32)
                                        .clipShape(Circle())
                                case .failure(_):
                                    fallbackProfileImage()
                                }
                            }
                        } else {
                            Image(item.userProfileImageName)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 32, height: 32)
                                .clipShape(Circle())
                        }

                        Text(item.userName)
                            .font(.system(size: 19, weight: .bold))
                            .foregroundColor(Colors.NebulaWhite)
                            .padding(.leading, 12)

                        Spacer()
                    }

                    .padding(.leading, 28)
                    .padding(.top, 20)

                    Spacer()

                    // Text("\(item.memoryStars) Memory Stars, \(item.constellations) Constellations")
                    Text("\(item.memoryStars) Memory Stars")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Colors.NebulaWhite)
                        .padding(.bottom, 24)
                        .frame(alignment: .center)
                }
            }

            Spacer()
                .frame(height: 16)

            MainButton(
                title: "Explore Galaxy",
                action: {
                    os.Logger.info("Go to \(item.userName)'s Galaxy!")
                    onExploreGalaxy()
                },
                isEnabled: true
            )

            Spacer()
                .frame(height: 16)
        }
        .frame(width: 432, height: 532)
        .background(LinearGradient.GradientCard)
        .cornerRadius(16)
    }
}

@ViewBuilder
private func fallbackProfileImage() -> some View {
    Image("profile_gray")
        .resizable()
        .scaledToFill()
        .frame(width: 32, height: 32)
        .clipShape(Circle())
}
