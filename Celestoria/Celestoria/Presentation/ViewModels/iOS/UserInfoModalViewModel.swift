//
//  UserInfoModalViewModel.swift
//  Celestoria
//
//  Created by Minjun Kim on 7/20/25.
//

import Foundation
import SwiftUI
import os
import Combine

@MainActor
final class UserInfoModalViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var userProfile: UserProfile?
    @Published var memoryCount: Int = 0
    @Published var followerCount: Int = 0 // TODO: Implement followers when available
    @Published var commentCount: Int = 0 // Comments feature not implemented yet
    @Published var likeCount: Int = 0
    
    // MARK: - Data Properties (for tabs)
    @Published var comments: [(Comment, UserProfile?)] = []
    @Published var likedMemories: [Memory] = []
    @Published var likedUsers: [(UserProfile?, Date, UUID)] = []
    @Published var memories: [Memory] = []
    @Published var selectedMemory: Memory? = nil
    @Published var errorMessage: String?
    
    // MARK: - UI State Properties
    @Published var isExpanded: Bool = false
    @Published var dragOffset: CGFloat = 0
    @Published var isLoading: Bool = false
    @Published var sortOption: SortOption = .latest
    
    // MARK: - Mock Data for Expanded Content
    @Published var mockMemories: [MockMemory] = []
    
    // MARK: - Dependencies
    private let diContainer: DIContainer
    private let userId: UUID
    private let appState: AppState
    private let logger = Logger(subsystem: "Celestoria", category: "UserInfoModalViewModel")
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Enums
    enum SortOption: String, CaseIterable {
        case latest = "Latest"
        case oldest = "Oldest"
        case popular = "Popular"
        
        var displayName: String { rawValue }
    }
    
    struct MockMemory: Identifiable {
        let id = UUID()
        let title: String
        let views: Int
        let daysAgo: Int
        let duration: String
    }
    
    // MARK: - Initialization
    init(diContainer: DIContainer, userId: UUID) {
        self.diContainer = diContainer
        self.userId = userId
        self.appState = diContainer.appState
        
        Logger.info("UserInfoModalViewModel: Initialized for userId: \(userId)")
        
        generateMockMemories()
        loadUserData()
        setupNotifications()
    }
    
    deinit {
        cancellables.removeAll()
    }
    
    // MARK: - Public Methods
    func loadUserData() {
        isLoading = true
        Task {
            async let profileTask = loadUserProfile()
            async let statsTask = loadUserStats()
            async let commentsTask = loadComments()
            async let likedMemoriesTask = loadLikedMemories()
            async let likedUsersTask = loadLikedUsers()
            async let memoriesTask = loadMemories()
            
            await profileTask
            await statsTask
            await commentsTask
            await likedMemoriesTask
            await likedUsersTask
            await memoriesTask
            
            isLoading = false
        }
    }
    
    // MARK: - UI State Management
    func toggleExpanded() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            isExpanded.toggle()
            if !isExpanded {
                dragOffset = 0
            }
        }
    }
    
    func handleDragChanged(_ value: DragGesture.Value) {
        if value.translation.height < 0 {
            dragOffset = value.translation.height * 0.3
        }
    }
    
    func handleDragEnded(_ value: DragGesture.Value) {
        if value.translation.height < -60 {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                isExpanded = true
                dragOffset = 0
            }
        } else {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                dragOffset = 0
            }
        }
    }
    
    func closeModal() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            isExpanded = false
        }
    }
    
    func changeSortOption(_ newOption: SortOption) {
        sortOption = newOption
        sortMemories()
    }
    
    func selectMemory(_ memory: Memory) {
        selectedMemory = memory
        Logger.info("UserInfoModalViewModel: Memory selected - ID: \(memory.id), Title: \(memory.title)")
    }
    
    func refreshProfileData() async {
        // 로딩 중 중복 호출 방지
        if isLoading { return }
        
        Logger.info("UserInfoModalViewModel: Manual profile refresh requested")
        // 로딩 상태를 명확하게 표시
        isLoading = true
        
        // 기존 데이터를 일시적으로 숨김
        let previousProfile = userProfile
        userProfile = nil
        
        // 약간의 지연으로 로딩 상태가 보이도록 함
        try? await Task.sleep(nanoseconds: 300_000_000) // 0.3초
        
        await loadUserProfile()
            await loadUserStats()
        
        // 로딩이 완료되면 isLoading을 false로 설정
        isLoading = false
    }
    
    // MARK: - Mock Data Generation
    private func generateMockMemories() {
        let durations = ["0:15", "0:32", "1:05", "0:48", "2:12", "0:23", "1:34", "0:56", "1:18", "0:41"]
        mockMemories = (1...10).map { index in
            MockMemory(
                title: "Memory \(index)",
                views: Int.random(in: 10...100),
                daysAgo: Int.random(in: 1...7),
                duration: durations.randomElement() ?? "0:30"
            )
        }
    }
    
    // MARK: - Private Methods
    private func loadUserProfile() async {
        do {
            userProfile = try await diContainer.profileUseCase.fetchProfileByUserId(userId: userId)
            
            // 프로필 이미지 미리 로딩
            if let profileImageURL = userProfile?.profileImageURL {
                Task {
                    await ImageCache.shared.preloadProfileImage(urlString: profileImageURL)
                }
            }
        } catch {
            Logger.error("Error loading user profile: \(error.localizedDescription)")
        }
    }
    
    private func loadUserStats() async {
        do {
            let memories = try await diContainer.memoryUseCase.execute(for: userId)
            memoryCount = memories.count
            
            var totalLikes = 0
            for memory in memories {
                let likeCount = try await diContainer.memoryRepository.getLikeCount(for: memory.id)
                totalLikes += likeCount
            }
            likeCount = totalLikes
            
            var totalComments = 0
            for memory in memories {
                let commentCount = try await diContainer.commentUseCase.getCommentCount(for: memory.id)
                totalComments += commentCount
            }
            commentCount = totalComments
            
        } catch {
            Logger.error("Error loading user stats: \(error.localizedDescription)")
            memoryCount = 0
            likeCount = 0
            commentCount = 0
        }
    }
    
    private func loadComments() async {
        do {
            let memories = try await diContainer.memoryUseCase.execute(for: userId)
            
            var allComments: [(Comment, UserProfile?)] = []
            for memory in memories {
                let commentsWithProfiles = try await diContainer.commentUseCase.fetchCommentsWithProfiles(for: memory.id)
                allComments.append(contentsOf: commentsWithProfiles)
            }
            allComments.sort { (comment1: (Comment, UserProfile?), comment2: (Comment, UserProfile?)) in
                comment1.0.createdAt > comment2.0.createdAt
            }
            self.comments = allComments
        } catch {
            Logger.error("Error loading comments: \(error.localizedDescription)")
        }
    }
    
    private func loadLikedMemories() async {
        do {
            let memories = try await diContainer.memoryUseCase.execute(for: userId)
            var memoriesWithLikes: [(Memory, Int)] = []
            for memory in memories {
                let likeCount = try await diContainer.memoryRepository.getLikeCount(for: memory.id)
                if likeCount > 0 { memoriesWithLikes.append((memory, likeCount)) }
            }
            memoriesWithLikes.sort { $0.1 > $1.1 }
            self.likedMemories = memoriesWithLikes.map { $0.0 }
        } catch {
            Logger.error("Error loading liked memories: \(error.localizedDescription)")
        }
    }
    
    private func loadLikedUsers() async {
        do {
            let memories = try await diContainer.memoryUseCase.execute(for: userId)
            var allLikedUsers: [(UserProfile?, Date, UUID)] = []
            
            for memory in memories {
                let likes = try await diContainer.memoryRepository.fetchLikes(for: memory.id)
                for like in likes {
                    let profile = try? await diContainer.profileUseCase.fetchProfileByUserId(userId: like.userId)
                    allLikedUsers.append((profile, like.createdAt, memory.id))
                }
            }
            
            // 좋아요 시간순으로 정렬 (최신순)
            self.likedUsers = allLikedUsers.sorted { $0.1 > $1.1 }
        } catch {
            Logger.error("Error loading liked users: \(error.localizedDescription)")
        }
    }
    
    private func loadMemories() async {
        do {
            let fetched = try await diContainer.memoryUseCase.execute(for: userId)
            self.memories = fetched
            sortMemories()
        } catch {
            Logger.error("Error loading memories: \(error.localizedDescription)")
            self.memories = []
        }
    }
    
    private func sortMemories() {
        switch sortOption {
        case .latest:
            memories.sort { $0.createdAt > $1.createdAt }
        case .oldest:
            memories.sort { $0.createdAt < $1.createdAt }
        case .popular:
            // For popular sorting, we could sort by like count in the future
            memories.sort { $0.createdAt > $1.createdAt }
        }
    }
    
    private func setupNotifications() {
        // AppState userProfile 변경 감지 (더 효율적인 프로필 업데이트)
        appState.$userProfile
            .compactMap { $0 }
            .filter { [weak self] profile in
                // 현재 모달의 사용자 프로필이 변경된 경우에만 반응
                guard let self = self else { return false }
                return profile.userId == self.userId
            }
            .sink { [weak self] updatedProfile in
                guard let self = self else { return }
                Task { @MainActor in
                    // 프로필 데이터만 즉시 업데이트 (로딩 없이)
                    self.userProfile = updatedProfile
                    self.logger.info("UserInfoModalViewModel: Profile updated from AppState - \(updatedProfile.name)")
                }
            }
            .store(in: &cancellables)
        
        // Comment notifications
        NotificationCenter.default.publisher(for: .commentAdded)
            .sink { [weak self] notification in
                guard let self = self,
                      let memoryId = notification.userInfo?[CommentNotificationKeys.memoryId] as? UUID else { return }
                Task { @MainActor in
                    let memories = try? await self.diContainer.memoryUseCase.execute(for: self.userId)
                    if let memories = memories, memories.contains(where: { $0.id == memoryId }) {
                        await self.loadComments()
                        await self.loadUserStats()
                    }
                }
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: .commentUpdated)
            .sink { [weak self] notification in
                guard let self = self,
                      let memoryId = notification.userInfo?[CommentNotificationKeys.memoryId] as? UUID else { return }
                Task { @MainActor in
                    let memories = try? await self.diContainer.memoryUseCase.execute(for: self.userId)
                    if let memories = memories, memories.contains(where: { $0.id == memoryId }) {
                        await self.loadComments()
                        await self.loadUserStats()
                    }
                }
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: .commentDeleted)
            .sink { [weak self] notification in
                guard let self = self,
                      let memoryId = notification.userInfo?[CommentNotificationKeys.memoryId] as? UUID else { return }
                Task { @MainActor in
                    let memories = try? await self.diContainer.memoryUseCase.execute(for: self.userId)
                    if let memories = memories, memories.contains(where: { $0.id == memoryId }) {
                        await self.loadComments()
                        await self.loadUserStats()
                    }
                }
            }
            .store(in: &cancellables)
        
        // Like notifications
        NotificationCenter.default.publisher(for: .likeAdded)
            .sink { [weak self] notification in
                guard let self = self,
                      let memoryId = notification.userInfo?[CommentNotificationKeys.memoryId] as? UUID else { return }
                Task { @MainActor in
                    let memories = try? await self.diContainer.memoryUseCase.execute(for: self.userId)
                    if let memories = memories, memories.contains(where: { $0.id == memoryId }) {
                        await self.loadLikedMemories()
                        await self.loadLikedUsers()
                        await self.loadUserStats()
                    }
                }
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: .likeRemoved)
            .sink { [weak self] notification in
                guard let self = self,
                      let memoryId = notification.userInfo?[CommentNotificationKeys.memoryId] as? UUID else { return }
                Task { @MainActor in
                    let memories = try? await self.diContainer.memoryUseCase.execute(for: self.userId)
                    if let memories = memories, memories.contains(where: { $0.id == memoryId }) {
                        await self.loadLikedMemories()
                        await self.loadLikedUsers()
                        await self.loadUserStats()
                    }
                }
            }
            .store(in: &cancellables)
    }
    

} 
