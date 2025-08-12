//
//  ExploreViewModel.swift
//  Celestoria
//
//  Created by Minjun Kim on 1/28/25.
//

import Foundation
import os

@MainActor
final class ExploreViewModel: ObservableObject {
    @Published var searchText: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    // 최종으로 View에서 그리는 데이터
    @Published var exploreUsers: [ExploreUser] = []
    @Published var popularUsers: [ExploreUser] = []
    @Published var latestUsers: [ExploreUser] = []
    @Published var isLoadingLatestUsers: Bool = false
    @Published var selectedUser: ExploreUser? = nil
    @Published var showingUserSpace: Bool = false
    @Published var showingSearchView: Bool = false
    @Published var showingOwnGalaxyPopup: Bool = false

    private let exploreUseCase: ExploreUseCase
    private let appState: AppState
    let diContainer: DIContainer

    init(exploreUseCase: ExploreUseCase, appState: AppState, diContainer: DIContainer) {
        self.exploreUseCase = exploreUseCase
        self.appState = appState
        self.diContainer = diContainer
    }


    /// 검색어 바뀔 때마다 즉시 검색: onChangeSearchText()
    /// (onSubmit 대신 즉시 검색을 원하면 유지)
    /// (Close버튼으로 검색어를 지울 때도 호출하려면 유지)
    func onChangeSearchText() {
        Task {
            await fetchExploreUsers()
        }
    }

    func fetchExploreUsers() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let currentUserId = appState.userId

            let users = try await exploreUseCase.fetchExploreUsers(
                searchText: searchText,
                excludeUserId: currentUserId
            )
            self.exploreUsers = users

        } catch {
            os.Logger.error("ExploreViewModel: fetchExploreUsers() failed: \(error.localizedDescription)")
            self.errorMessage = "Fail to fetch user list"
        }
    }
    
    func fetchPopularUsers() async {
        do {
            let currentUserId = appState.userId
            
            let users = try await exploreUseCase.fetchPopularUsers(
                searchText: searchText,
                excludeUserId: currentUserId
            )
            self.popularUsers = users
            
        } catch {
            os.Logger.error("ExploreViewModel: fetchPopularUsers() failed: \(error.localizedDescription)")
            self.errorMessage = "Fail to fetch popular users"
        }
    }
    
    func fetchLatestUsers() async {
        isLoadingLatestUsers = true
        defer { isLoadingLatestUsers = false }
        
        do {
            let currentUserId = appState.userId
            
            let users = try await exploreUseCase.fetchLatestUsers(
                searchText: searchText,
                excludeUserId: currentUserId,
                page: 1,
                limit: 10
            )
            self.latestUsers = users
            
        } catch {
            os.Logger.error("ExploreViewModel: fetchLatestUsers() failed: \(error.localizedDescription)")
            self.errorMessage = "Fail to fetch latest users"
        }
    }
    
    func loadMoreLatestUsers() async {
        guard !isLoadingLatestUsers else { return }
        
        isLoadingLatestUsers = true
        defer { isLoadingLatestUsers = false }
        
        do {
            let currentUserId = appState.userId
            let nextPage = (latestUsers.count / 10) + 1
            
            let moreUsers = try await exploreUseCase.fetchLatestUsers(
                searchText: searchText,
                excludeUserId: currentUserId,
                page: nextPage,
                limit: 10
            )
            
            // 중복 데이터 방지: 이미 있는 유저는 추가하지 않음
            let existingUserIds = Set(latestUsers.map { $0.profile.userId })
            let newUsers = moreUsers.filter { !existingUserIds.contains($0.profile.userId) }
            
            if !newUsers.isEmpty {
                self.latestUsers.append(contentsOf: newUsers)
            }
            
        } catch {
            os.Logger.error("ExploreViewModel: loadMoreLatestUsers() failed: \(error.localizedDescription)")
            self.errorMessage = "Fail to load more latest users"
        }
    }

    
    func getUser(by userId: UUID) -> ExploreUser? {
        exploreUsers.first(where: { $0.profile.userId == userId }) ??
        popularUsers.first(where: { $0.profile.userId == userId }) ??
        latestUsers.first(where: { $0.profile.userId == userId })
    }
    
    func isCurrentUser(_ user: ExploreUser) -> Bool {
        return user.profile.userId == appState.userId
    }
    
    func getCardItem(by userId: UUID) -> ExploreUserCardItem? {
        // exploreUsers, popularUsers, latestUsers 모두에서 유저 찾기
        let user = getUser(by: userId) ?? 
                   popularUsers.first(where: { $0.profile.userId == userId }) ??
                   latestUsers.first(where: { $0.profile.userId == userId })
        guard let user = user else { return nil }

        let profileImageName: String
        let isCustomImage: Bool

        if let key = user.profile.profileKey,
           let predefined = PredefinedProfileImage.fromKey(key) {
            profileImageName = predefined.rawValue // "profile_blue" 등
            isCustomImage = false
        } else if let url = user.profile.profileImageURL {
            profileImageName = url
            isCustomImage = url.lowercased().hasPrefix("http")
        } else {
            profileImageName = PredefinedProfileImage.profile_gray.rawValue
            isCustomImage = false
        }

        return ExploreUserCardItem(
            userName: user.profile.name,
            userProfileImageName: profileImageName,
            memoryStars: user.memoryCount,
            likeCount: user.likeCount,
            imageName: mapThumbnailIdToImageName(user.profile.spaceThumbnailId),
            isCustomImage: isCustomImage
        )
    }
    
    /// space_thumbnail_id -> 실제 썸네일 이미지 이름
    func mapThumbnailIdToImageName(_ spaceThumbnailId: String?) -> String {
        guard let thumbnailId = spaceThumbnailId else {
            return "Thumbnail1"
        }
        // 예: "1"~"6" => Thumbnail1 ~ Thumbnail6
        return "Thumbnail\(thumbnailId)"
    }
}
