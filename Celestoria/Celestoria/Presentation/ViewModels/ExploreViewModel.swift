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

    private let exploreUseCase: ExploreUseCase
    private let appModel: AppModel

    init(exploreUseCase: ExploreUseCase, appModel: AppModel) {
        self.exploreUseCase = exploreUseCase
        self.appModel = appModel
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
            let currentUserId = appModel.userId

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

    
    func getUser(by userId: UUID) -> ExploreUser? {
        exploreUsers.first(where: { $0.profile.userId == userId })
    }
    
    func getCardItem(by userId: UUID) -> ExploreUserCardItem? {
        guard let user = getUser(by: userId) else { return nil }
        return ExploreUserCardItem(
            userName: user.profile.name,
            userProfileImageName: user.profile.profileImageURL ?? "CardUserProfileImage",
            memoryStars: user.memoryCount,
            imageName: mapThumbnailIdToImageName(user.profile.spaceThumbnailId)
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
