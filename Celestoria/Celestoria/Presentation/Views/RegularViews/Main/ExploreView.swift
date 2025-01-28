//
//  ExploreView.swift
//  Celestoria
//
//  Created by Park Seyoung on 1/20/25.
//

import SwiftUI
import os

struct ExploreView: View {
    @EnvironmentObject private var appModel: AppModel
    @EnvironmentObject var spaceCoordinator: SpaceCoordinator
    @EnvironmentObject var exploreViewModel: ExploreViewModel

    @Environment(\.dismissWindow) private var dismissWindow
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // NavigationBar
                NavigationBar(
                    title: "Explore",
                    action: {
                        appModel.activeScreen = .main
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

                    Text("Explore other people’s Galaxy!")
                        .foregroundColor(Color.NebulaWhite)
                        .font(.system(size: 22, weight: .bold))
                        .padding(.top, 32)
                    
                } else {
                    // 유저 카드 목록
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 20) {
                            ForEach(exploreViewModel.exploreUsers, id: \.profile.id) { user in
                                let cardItem = ExploreUserCardItem(
                                    userName: user.profile.name,
                                    userProfileImageName: user.profile.profileImageURL ?? "CardUserProfileImage",
                                    memoryStars: user.memoryCount,
                                    // constellations: 0, // Todo
                                    imageName: exploreViewModel.mapThumbnailIdToImageName(user.profile.spaceThumbnailId)
                                )

                                ExploreUserCard(
                                    item: cardItem,
                                    onExploreGalaxy: {
                                        guard !appModel.showExploreNavigatorView else {
                                            os.Logger.info("Explore Navigator View is already opened")
                                            return
                                        }
                                        
                                        os.Logger.info("Displaying Explore Navigator View")
                                        appModel.showExploreNavigatorView = true
                                        openWindow(value: user.profile.userId)
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 48)
                    }
                    .padding(.top, 44)
                }

                Spacer()
            }
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
                                    .fill(Color.NebulaBlack)
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
                                                .foregroundColor(Color.NebulaWhite)
                                                .font(.system(size: 16))
                                                .padding(.leading, 8)
                                        }
                                        
                                        TextField("", text: $exploreViewModel.searchText)
                                            .submitLabel(.search)
                                            .foregroundColor(Color.NebulaWhite)
                                            .font(.system(size: 16))
                                            .tint(Color.NebulaWhite)
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
                        if let url = URL(string: item.userProfileImageName),
                        // 간단 예: "http"로 시작하면 외부 URL로 간주
                        item.userProfileImageName.lowercased().hasPrefix("http") {
                            // 외부 URL
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .empty:
                                    // 아직 로드되지 않은 상태
                                    ProgressView()
                                        .frame(width: 32, height: 32)
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 32, height: 32)
                                        .clipShape(Circle())
                                case .failure(_):
                                    // 로드 실패 → 기본 이미지
                                    Image("CardUserProfileImage")
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 32, height: 32)
                                        .clipShape(Circle())
                                }
                            }
                        } else {
                            // 외부 URL이 아니면, 로컬 이미지로 처리
                            Image("CardUserProfileImage")
                                .resizable()
                                .scaledToFill()
                                .frame(width: 32, height: 32)
                                .clipShape(Circle())
                        }

                        Text(item.userName)
                            .font(.system(size: 19, weight: .bold))
                            .foregroundColor(.NebulaWhite)
                            .padding(.leading, 12)

                        Spacer()
                    }

                    .padding(.leading, 28)
                    .padding(.top, 20)

                    Spacer()

                    // Text("\(item.memoryStars) Memory Stars, \(item.constellations) Constellations")
                    Text("\(item.memoryStars) Memory Stars")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.NebulaWhite)
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
