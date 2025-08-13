//
//  UserInfoModalViewModel.swift
//  Celestoria
//
//  Created by Seyoung Park on 8/7/25.
//

import Foundation
import SwiftUI
import os
import Combine

@MainActor
final class UserInfoModalViewModel: ObservableObject {
    // MARK: - Dependencies
    private let userId: UUID
    private let diContainer: DIContainer
    private let logger = Logger(subsystem: "Celestoria", category: "UserInfoModalViewModel")
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Published Properties (Data)
    @Published var userProfile: UserProfile?
    @Published var memoryCount: Int = 0
    @Published var likeCount: Int = 0
    @Published var commentCount: Int = 0
    @Published var comments: [(Comment, UserProfile?)] = []
    @Published var likedMemories: [Memory] = []
    @Published var likedUsers: [(UserProfile?, Date, UUID)] = []
    @Published var memories: [Memory] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // MARK: - Sorting
    enum SortOption: String, CaseIterable {
        case latest = "Latest"
        case oldest = "Oldest"
        
        var displayName: String { rawValue }
    }
    @Published var sortOption: SortOption = .latest
    
    // MARK: - Published Properties (UI State expected by View)
    @Published var isExpanded: Bool = false
    @Published var dragOffset: CGFloat = 0
    @Published var selectedMemory: Memory? = nil
    
    // MARK: - Initialization
    init(userId: UUID, diContainer: DIContainer) {
        self.userId = userId
        self.diContainer = diContainer
        
        setupNotifications()
    }
    
    deinit {
        cancellables.removeAll()
    }
    
    // MARK: - Public Methods
    func loadUserData() async {
        isLoading = true
        defer { isLoading = false }
        
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
    }
    
    func refreshProfileData() async {
        await loadUserData()
    }
    
    // MARK: - UI State Controls (used by View)
    func toggleExpanded() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            isExpanded.toggle()
            if !isExpanded { dragOffset = 0 }
        }
    }
    
    func handleDragChanged(_ value: DragGesture.Value) {
        if isExpanded {
            if value.translation.height > 0 { dragOffset = value.translation.height * 0.3 }
        } else {
            if value.translation.height < 0 { dragOffset = value.translation.height * 0.3 }
        }
    }
    
    func handleDragEnded(_ value: DragGesture.Value) {
        if isExpanded {
            if value.translation.height > 100 {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    isExpanded = false
                    dragOffset = 0
                }
            } else {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) { dragOffset = 0 }
            }
        } else {
            if value.translation.height < -60 {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    isExpanded = true
                    dragOffset = 0
                }
            } else {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) { dragOffset = 0 }
            }
        }
    }
    
    func expandModal() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            isExpanded = true
            dragOffset = 0
        }
    }
    
    func closeModal() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            isExpanded = false
            dragOffset = 0
        }
    }
    
    func selectMemory(_ memory: Memory) {
        selectedMemory = memory
        logger.info("UserInfoModalViewModel: Memory selected - ID: \(memory.id), Title: \(memory.title)")
    }
    
    func changeSortOption(_ newOption: SortOption) {
        sortOption = newOption
        sortMemories()
    }
    
    private func sortMemories() {
        switch sortOption {
        case .latest:
            memories.sort { $0.createdAt > $1.createdAt }
        case .oldest:
            memories.sort { $0.createdAt < $1.createdAt }
        }
    }
    
    // MARK: - Private Methods
    private func loadUserProfile() async {
        do {
            userProfile = try await diContainer.profileUseCase.fetchProfileByUserId(userId: userId)
            
            if let profileImageURL = userProfile?.profileImageURL {
                Task { await ImageCache.shared.preloadProfileImage(urlString: profileImageURL) }
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
    
    private func setupNotifications() {
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
        
        // Likes
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
