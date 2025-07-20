//
//  MemoryDetailViewModel.swift
//  Celestoria
//
//  Created by Park Seyoung on 1/27/25.
//

import Foundation
import Combine
import os

@MainActor
final class MemoryDetailViewModel: ObservableObject {
    private let memoryRepository: MemoryRepository
    private let deleteMemoryUseCase: DeleteMemoryUseCase
    private let logger = Logger(subsystem: "com.celestoria", category: "MemoryDetailViewModel")
    private let profileUseCase: ProfileUseCase?
    private let authRepository: AuthRepositoryProtocol?
    private let appState: AppState
    private let spaceCoordinator: SpaceCoordinator
    
    @Published private(set) var memory: Memory
    @Published var popupData: PopupData? // Data for the popup
    @Published var formattedDate: String = ""
    @Published var videoURLStatus: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var userProfile: UserProfile? = nil
    @Published var isDeleting: Bool = false
    @Published var likeCount: Int = 0
    @Published var isLiked: Bool = false
    @Published var isLikeLoading: Bool = false
    
    init(
        memory: Memory,
        memoryRepository: MemoryRepository,
        profileUseCase: ProfileUseCase? = nil,
        authRepository: AuthRepositoryProtocol? = nil,
        appState: AppState,
        spaceCoordinator: SpaceCoordinator
    ) {
        self.memory = memory
        self.memoryRepository = memoryRepository
        self.deleteMemoryUseCase = DeleteMemoryUseCase(memoryRepository: memoryRepository)
        self.profileUseCase = profileUseCase
        self.authRepository = authRepository
        self.appState = appState
        self.spaceCoordinator = spaceCoordinator

        formatDate()
        checkVideoURL()
        
        // ★ 메모리 작성자 프로필 가져오기
        Task {
            await fetchUserProfile()
            await loadLikeData()
        }
    }

    private func formatDate() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd HH:mm"
        formattedDate = formatter.string(from: memory.createdAt)
    }

    private func checkVideoURL() {
        os.Logger.info("🔍 checkVideoURL 시작")
        
        guard let urlString = memory.videoURL, let url = URL(string: urlString) else {
            os.Logger.info("❌ 유효하지 않은 URL: \(String(describing: memory.videoURL))")
            videoURLStatus = "Invalid URL"
            return
        }
        
        os.Logger.info("📝 체크할 URL: \(urlString)")

        Task {
            do {
                os.Logger.info("⏳ HEAD 요청 시작")
                let config = URLSessionConfiguration.default
                config.timeoutIntervalForRequest = 30
                let session = URLSession(configuration: config)
                
                var request = URLRequest(url: url)
                request.httpMethod = "HEAD"
                
                let (_, response) = try await session.data(for: request)
                
                if let httpResponse = response as? HTTPURLResponse {
                    let contentLength = httpResponse.value(forHTTPHeaderField: "Content-Length")
                    let message = "✅ HTTP Status: \(httpResponse.statusCode)" + (contentLength.map { ", size: \($0) bytes" } ?? "")
                    os.Logger.info(message)
                    videoURLStatus = message
                } else {
                    let message = "⚠️ Non-HTTP response"
                    os.Logger.info(message)
                    videoURLStatus = message
                }
            } catch let error as NSError {
                let errorMessage: String
                if error.domain == NSURLErrorDomain && error.code == NSURLErrorTimedOut {
                    errorMessage = "⏰ Connection timed out"
                } else {
                    errorMessage = "❌ Error: \(error.localizedDescription)"
                }
                os.Logger.error(errorMessage)
                videoURLStatus = errorMessage
            }
        }
    }
    
    private func fetchUserProfile() async {
        guard let profileUseCase = profileUseCase else { return }
        do {
            let fetchedProfile = try await profileUseCase.fetchProfileByUserId(userId: memory.userId)
            self.userProfile = fetchedProfile
        } catch {
            logger.error("Failed to fetch user profile: \(error.localizedDescription)")
        }
    }
    
    // MARK: - 좋아요 관련 메서드
    
    private func loadLikeData() async {
        guard let currentUserId = appState.userId else { return }
        
        do {
            // 좋아요 수와 현재 사용자의 좋아요 상태를 동시에 로드
            async let likeCountResult = memoryRepository.getLikeCount(for: self.memory.id)
            async let hasLikedResult = memoryRepository.hasLiked(memoryId: self.memory.id, userId: currentUserId)
            
            let (count, liked) = try await (likeCountResult, hasLikedResult)
            
            self.likeCount = count
            self.isLiked = liked
        } catch {
            logger.error("Failed to load like data: \(error.localizedDescription)")
        }
    }
    
    func toggleLike() async {
        guard let currentUserId = appState.userId else { return }
        guard !isLikeLoading else { return }
        
        // Check if user is trying to like their own memory
        if memory.userId == currentUserId {
            logger.warning("User cannot like their own memory")
            errorMessage = "자신의 메모리에는 좋아요를 할 수 없습니다."
            return
        }
        
        isLikeLoading = true
        defer { isLikeLoading = false }
        
        do {
            if isLiked {
                // 좋아요 취소
                try await memoryRepository.deleteLike(memoryId: self.memory.id, userId: currentUserId)
                likeCount = max(0, likeCount - 1)
                isLiked = false
                logger.info("Like removed for memory: \(self.memory.id)")
            } else {
                // 좋아요 추가
                logger.info("Attempting to create like - memoryId: \(self.memory.id), userId: \(currentUserId), memoryOwnerId: \(self.memory.userId)")
                try await memoryRepository.createLike(memoryId: self.memory.id, userId: currentUserId)
                likeCount += 1
                isLiked = true
                logger.info("Like added for memory: \(self.memory.id)")
            }
        } catch {
            logger.error("Failed to toggle like: \(error.localizedDescription)")
            errorMessage = "좋아요 처리 중 오류가 발생했습니다."
        }
    }

    func deleteMemory() async throws {
        isLoading = true
        defer { isLoading = false }
        do {
            logger.info("Attempting to delete memory with ID: \(self.memory.id.uuidString)")
            try await deleteMemoryUseCase.execute(
                memoryId: self.memory.id,
                videoPath: self.memory.videoURL,
                thumbnailPath: self.memory.thumbnailURL
            )
            logger.info("Memory successfully deleted.")
        } catch {
            logger.error("Failed to delete memory: \(error.localizedDescription)")
            errorMessage = "Failed to delete memory. Please try again."
            throw error
        }
    }

    func showReportPopup() {
        popupData = PopupData(
            title: "Do you want to report this post?",
            notes: "Are you sure you report this post?\nThis action cannot be undone.",
            leadingButtonText: "No",
            trailingButtonText: "Yes",
            buttonImageString: "xmark",
            circularAction: { [weak self] in
                self?.popupData = nil
            },
            leadingButtonAction: { [weak self] in
                self?.popupData = nil
            },
            trailingButtonAction: { [weak self] in
                guard let self = self else { return }
                Task {
                    if let currentUserId = self.appState.userId {
                        await self.processReport(reporterId: currentUserId)
                    }
                }
            }
        )
    }
    
    private func processReport(reporterId: UUID) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // 이미 신고했는지 확인
            if try await memoryRepository.hasReported(memoryId: memory.id, reporterId: reporterId) {
                showReportCompletionPopup(
                    title: "Already Reported",
                    message: "You have already reported this post.\nThank you for helping us maintain a safe environment.",
                    buttonText: "OK"
                )
                return
            }
            
            // 신고 처리
            try await memoryRepository.createReport(memoryId: memory.id, reporterId: reporterId)
            
            // 현재 메모리 상태 업데이트
            if let updatedMemories: [Memory] = try? await memoryRepository.fetchMemories(for: memory.userId) {
                if let updatedMemory = updatedMemories.first(where: { $0.id == memory.id }) {
                    self.memory = updatedMemory
                }
            }
            
            showReportCompletionPopup(
                title: "The report has been completed.",
                message: "Thank you for sending us your report for better service!\nWe will take your valuable comments into consideration.",
                buttonText: "Complete"
            )
            
        } catch {
            showReportCompletionPopup(
                title: "Report Failed",
                message: "Failed to process your report: \(error.localizedDescription)",
                buttonText: "OK"
            )
            logger.error("Report error: \(error.localizedDescription)")
        }
    }
    
    private func showReportCompletionPopup(title: String, message: String, buttonText: String) {
        popupData = PopupData(
            title: title,
            notes: message,
            leadingButtonText: "",
            trailingButtonText: buttonText,
            buttonImageString: "xmark",
            circularAction: { [weak self] in
                self?.popupData = nil
            },
            leadingButtonAction: { [weak self] in
                self?.popupData = nil
            },
            trailingButtonAction: { [weak self] in
                guard let self = self else { return }
                self.popupData = nil
                NotificationCenter.default.post(name: .dismissMemoryDetailViewOnly, object: nil)
            }
        )
    }

    func showBlockPopup() {
        popupData = PopupData(
            title: "Block this user?",
            notes: "Are you sure you want to block this user?\nThis action cannot be undone.",
            leadingButtonText: "No",
            trailingButtonText: "Yes",
            buttonImageString: "xmark",
            circularAction: { [weak self] in
                self?.popupData = nil
            },
            leadingButtonAction: { [weak self] in
                self?.popupData = nil
            },
            trailingButtonAction: { [weak self] in
                guard let self = self else { return }
                Task {
                    if let currentUserId = self.appState.userId {
                        await self.processBlock(currentUserId: currentUserId)
                    }
                }
            }
        )
    }

    private func processBlock(currentUserId: UUID) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await authRepository?.blockUser(reporterId: currentUserId, blockedUserId: memory.userId)
            showBlockCompletionPopup()
        } catch {
            logger.error("Block error: \(error.localizedDescription)")
            showBlockCompletionPopup(error: error)
        }
    }

    private func showBlockCompletionPopup(error: Error? = nil) {
        if let error = error {
            popupData = PopupData(
                title: "Block Failed",
                notes: "Failed to block user: \(error.localizedDescription)",
                leadingButtonText: "",
                trailingButtonText: "OK",
                buttonImageString: "xmark",
                circularAction: { [weak self] in
                    self?.popupData = nil
                },
                leadingButtonAction: { [weak self] in
                    self?.popupData = nil
                },
                trailingButtonAction: { [weak self] in
                    self?.popupData = nil
                }
            )
        } else {
            popupData = PopupData(
                title: "User blocked!",
                notes: "Manage blocked users in Settings",
                leadingButtonText: "",
                trailingButtonText: "OK",
                buttonImageString: "xmark",
                circularAction: { [weak self] in
                    self?.popupData = nil
                },
                leadingButtonAction: { [weak self] in
                    self?.popupData = nil
                },
                trailingButtonAction: { [weak self] in
                    guard let self = self else { return }
                    self.popupData = nil
                    NotificationCenter.default.post(name: .dismissAllAndGoMain, object: nil)
                }
            )
        }
    }

    func showDeletePopup(dismissWindow: @escaping () -> Void, onMemoryDeleted: @escaping (Memory) -> Void) {
        self.isDeleting = true
        popupData = PopupData(
            title: "Delete Memory Star",
            notes: "Are you sure you want to delete this?\nThis action cannot be undone.",
            leadingButtonText: "Cancel",
            trailingButtonText: "Delete",
            buttonImageString: "xmark",
            circularAction: { [weak self] in
                // 팝업 닫기
                self?.popupData = nil
            },
            leadingButtonAction: { [weak self] in
                //팝업 닫기
                self?.popupData = nil
            },
            trailingButtonAction: { [weak self] in
                Task {
                        defer { self?.isDeleting = false }
                        do {
                            try await self?.deleteMemory()
                            if let deletedMemory = self?.memory {
                                onMemoryDeleted(deletedMemory)
                            }
                            self?.popupData = nil
                            // 삭제 작업 완료 후에 뷰 닫기
                            await MainActor.run {
                                dismissWindow()
                            }
                        } catch {
                            // 에러 처리
                            await MainActor.run {
                                self?.errorMessage = error.localizedDescription
                            }
                        }
                    }
            }
        )
    }
}

// NotificationCenter extension for custom notification
extension Notification.Name {
    static let dismissMemoryDetailView = Notification.Name("dismissMemoryDetailView")
    static let dismissMemoryDetailViewOnly = Notification.Name("dismissMemoryDetailViewOnly")
    static let dismissAllAndGoMain = Notification.Name("dismissAllAndGoMain")
}
