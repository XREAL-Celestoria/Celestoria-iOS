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
    
    @Published private(set) var memory: Memory
    @Published var popupData: PopupData? // Data for the popup
    @Published var formattedDate: String = ""
    @Published var videoURLStatus: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var userProfile: UserProfile? = nil
    
    init(
        memory: Memory,
        memoryRepository: MemoryRepository,
        profileUseCase: ProfileUseCase? = nil
    ) {
        self.memory = memory
        self.memoryRepository = memoryRepository
        self.deleteMemoryUseCase = DeleteMemoryUseCase(memoryRepository: memoryRepository)
        self.profileUseCase = profileUseCase

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

    func showDeletePopup(dismissWindow: @escaping () -> Void, onMemoryDeleted: @escaping (Memory) -> Void) {
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
                    do {
                        try await self?.deleteMemory()
                        if let deletedMemory = self?.memory {
                            onMemoryDeleted(deletedMemory)
                        }
                        self?.popupData = nil
                        dismissWindow()
                    } catch {
                        // 에러 처리
                    }
                }
            }
        )
    }
}
