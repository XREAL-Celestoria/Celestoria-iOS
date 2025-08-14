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
    @Published var isInitialLoading: Bool = false
    @Published var errorMessage: String? = nil

    // 최종으로 View에서 그리는 데이터
    @Published var exploreUsers: [ExploreUser] = []            // 검색 결과 전용
    @Published var mostStarsUsers: [ExploreUser] = []          // 메인(모스트 스타) 전용
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
    private var hasLoadedInitialExploreData: Bool = false

    init(exploreUseCase: ExploreUseCase, appState: AppState, diContainer: DIContainer) {
        self.exploreUseCase = exploreUseCase
        self.appState = appState
        self.diContainer = diContainer
    }

    /// 익스플로어 뷰 최초 진입 시 필요한 데이터 일괄 로드
    func loadInitialExploreData() async {
        // 이미 최초 로드가 끝났다면 재로딩/로딩오버레이 생략
        if hasLoadedInitialExploreData {
            return
        }

        // 최초 진입 로딩 오버레이 표시 (최소 0.2초 보장)
        isInitialLoading = true
        let loadingStartAt = Date()

        // 가능한 한 병렬로 불러오기
        async let most = fetchMostStarsUsers()
        async let popular = fetchPopularUsers()
        async let latest = fetchLatestUsers()
        _ = await (most, popular, latest)

        // 최소 로딩 시간 보장
        let elapsed = Date().timeIntervalSince(loadingStartAt)
        let minimumLoadingDuration: TimeInterval = 0.2
        if elapsed < minimumLoadingDuration {
            let remaining = minimumLoadingDuration - elapsed
            let nanos = UInt64(remaining * 1_000_000_000)
            try? await Task.sleep(nanoseconds: nanos)
        }

        isInitialLoading = false
        hasLoadedInitialExploreData = true
    }

    /// 검색어 바뀔 때마다 즉시 검색: onChangeSearchText()
    /// (onSubmit 대신 즉시 검색을 원하면 유지)
    /// (Close버튼으로 검색어를 지울 때도 호출하려면 유지)
    func onChangeSearchText() {
        Task {
            if searchText.isEmpty {
                // 검색어가 비어있을 때는 인기 유저들을 로드 (suggest용)
                await fetchPopularUsers()
            } else {
                // 검색어가 있을 때는 검색 결과를 로드
                await fetchExploreUsers()
            }
        }
    }

    /// 검색 결과 로드 (searchText 기준)
    func fetchExploreUsers() async {
        isLoading = true
        defer { isLoading = false }

        do {
            // 현재 유저도 포함하도록 excludeUserId를 nil로 설정
            let users = try await exploreUseCase.fetchExploreUsers(
                searchText: searchText,
                excludeUserId: nil  // nil로 설정하여 현재 유저도 포함
            )
            self.exploreUsers = users
        } catch {
            os.Logger.error("ExploreViewModel: fetchExploreUsers() failed: \(error.localizedDescription)")
            self.errorMessage = "Fail to fetch user list"
        }
    }

    /// 메인(모스트 스탈)용 데이터 로드 (검색어와 무관, 상단 섹션 전용)
    func fetchMostStarsUsers() async {
        do {
            // 현재 유저도 포함하도록 excludeUserId를 nil로 설정
            let users = try await exploreUseCase.fetchExploreUsers(
                searchText: "",
                excludeUserId: nil  // nil로 설정하여 현재 유저도 포함
            )
            // 별 수(메모리 카운트) 기준 내림차순 정렬 후 보관
            self.mostStarsUsers = users.sorted { $0.memoryCount > $1.memoryCount }
        } catch {
            os.Logger.error("ExploreViewModel: fetchMostStarsUsers() failed: \(error.localizedDescription)")
            self.errorMessage = "Fail to fetch most stars users"
        }
    }

    func fetchPopularUsers() async {
        do {
            // 현재 유저도 포함하도록 excludeUserId를 nil로 설정
            let users = try await exploreUseCase.fetchPopularUsers(
                searchText: searchText,
                excludeUserId: nil  // nil로 설정하여 현재 유저도 포함
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
            // 현재 유저도 포함하도록 excludeUserId를 nil로 설정
            let users = try await exploreUseCase.fetchUsersByLatestMemoryUpload(
                searchText: searchText,
                excludeUserId: nil,  // nil로 설정하여 현재 유저도 포함
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
            let nextPage = (latestUsers.count / 10) + 1
            let moreUsers = try await exploreUseCase.fetchUsersByLatestMemoryUpload(
                searchText: searchText,
                excludeUserId: nil,  // nil로 설정하여 현재 유저도 포함
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
    
    /// 최근 메모리 업로드 순서로 정렬된 유저 목록 가져오기
    func fetchUsersByLatestMemoryUpload() async {
        isLoadingLatestUsers = true
        defer { isLoadingLatestUsers = false }

        do {
            let currentUserId = appState.userId
            let users = try await exploreUseCase.fetchUsersByLatestMemoryUpload(
                searchText: searchText,
                excludeUserId: currentUserId,
                page: 1,
                limit: 10
            )
            self.latestUsers = users
        } catch {
            os.Logger.error("ExploreViewModel: fetchUsersByLatestMemoryUpload() failed: \(error.localizedDescription)")
            self.errorMessage = "Fail to fetch users by latest memory upload"
        }
    }
    
    /// 최근 메모리 업로드 순서로 정렬된 유저 더 로드하기
    func loadMoreUsersByLatestMemoryUpload() async {
        guard !isLoadingLatestUsers else { return }
        isLoadingLatestUsers = true
        defer { isLoadingLatestUsers = false }

        do {
            let currentUserId = appState.userId
            let nextPage = (latestUsers.count / 10) + 1
            let moreUsers = try await exploreUseCase.fetchUsersByLatestMemoryUpload(
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
            os.Logger.error("ExploreViewModel: loadMoreUsersByLatestMemoryUpload() failed: \(error.localizedDescription)")
            self.errorMessage = "Fail to load more users by latest memory upload"
        }
    }

    func getUser(by userId: UUID) -> ExploreUser? {
        mostStarsUsers.first(where: { $0.profile.userId == userId }) ??
        exploreUsers.first(where: { $0.profile.userId == userId }) ??
        popularUsers.first(where: { $0.profile.userId == userId }) ??
        latestUsers.first(where: { $0.profile.userId == userId })
    }

    func isCurrentUser(_ user: ExploreUser) -> Bool {
        return user.profile.userId == appState.userId
    }

    func getCardItem(by userId: UUID) -> ExploreUserCardItem? {
        // exploreUsers, mostStarsUsers, popularUsers, latestUsers 모두에서 유저 찾기
        let user = getUser(by: userId)
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

    /// 검색 결과 초기화
    func clearSearchResults() {
        searchText = ""
        exploreUsers = []
    }

    /// 모스트 스탈스 데이터 리프레시 (검색과 분리)
    func refreshMostStarsData() async {
        await fetchMostStarsUsers()
    }
}
