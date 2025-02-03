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
    private let appModel: AppModel
    private let spaceCoordinator: SpaceCoordinator
    
    @Published private(set) var memory: Memory
    @Published var popupData: PopupData? // Data for the popup
    @Published var formattedDate: String = ""
    @Published var videoURLStatus: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var userProfile: UserProfile? = nil
    @Published var isDeleting: Bool = false
    
    init(
        memory: Memory,
        memoryRepository: MemoryRepository,
        profileUseCase: ProfileUseCase? = nil,
        authRepository: AuthRepositoryProtocol? = nil,
        appModel: AppModel,
        spaceCoordinator: SpaceCoordinator
    ) {
        self.memory = memory
        self.memoryRepository = memoryRepository
        self.deleteMemoryUseCase = DeleteMemoryUseCase(memoryRepository: memoryRepository)
        self.profileUseCase = profileUseCase
        self.authRepository = authRepository
        self.appModel = appModel
        self.spaceCoordinator = spaceCoordinator

        formatDate()
        checkVideoURL()
        
        // ★ 메모리 작성자 프로필 가져오기
        Task {
            await fetchUserProfile()
        }
    }

    private func formatDate() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd HH:mm"
        formattedDate = formatter.string(from: memory.createdAt)
    }

    private func checkVideoURL() {
        guard let urlString = memory.videoURL, let url = URL(string: urlString) else {
            videoURLStatus = "Invalid URL"
            return
        }

        Task {
            do {
                let (data, response) = try await URLSession.shared.data(from: url)
                if let httpResponse = response as? HTTPURLResponse {
                    videoURLStatus = "HTTP Status: \(httpResponse.statusCode), size: \(data.count) bytes"
                } else {
                    videoURLStatus = "Data size: \(data.count)"
                }
            } catch {
                videoURLStatus = "Error: \(error.localizedDescription)"
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
                    if let currentUserId = self.appModel.userId {
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
                    if let currentUserId = self.appModel.userId {
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
