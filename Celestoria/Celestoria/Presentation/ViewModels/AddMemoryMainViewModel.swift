//
//  AddMemoryMainViewModel.swift
//  Celestoria
//
//  Created by Park Seyoung on 1/23/25.
//

import Foundation
import Combine
import SwiftUI
import PhotosUI
@preconcurrency import AVFoundation
import MetalKit
import CoreImage
import os

@MainActor
class AddMemoryMainViewModel: ObservableObject {
    private let logger = Logger(subsystem: "com.Celestoria.Celestoria", category: "AddMemoryMainViewModel")
    private let createMemoryUseCase: CreateMemoryUseCase
    private let appState: AppState
    
    @Published var popupData: PopupData?
    @Published var isPickerBlocked = true
    @Published var isThumbnailGenerating: Bool = false
    @Published var errorMessage: String?
    @Published var selectedCategory: Category?
    @Published var selectedVideoItem: PhotosPickerItem?
    @Published private(set) var lastUploadedMemory: Memory?
    @Published var thumbnailImage: UIImage?
    @Published var isUploading = false
    @Published var uploadStatus: String = ""
    
    @Published var title: String = ""
    @Published var note: String = ""
    
    private let MAX_FILE_SIZE: Int64 = 1024 * 1024 * 1024 // 1GB in bytes

    @Published var uploadProgress: Double = 0
    @Published var uploadingFileSize: String = ""
    
    var isUploadEnabled: Bool {
        selectedVideoItem != nil &&
        thumbnailImage != nil &&
        selectedCategory != nil &&
        !title.trimmingCharacters(in: .whitespaces).isEmpty &&
        !note.trimmingCharacters(in: .whitespaces).isEmpty &&
        note.count <= 500
    }
    
    init(createMemoryUseCase: CreateMemoryUseCase, appState: AppState) {
        self.createMemoryUseCase = createMemoryUseCase
        self.appState = appState
    }
    
    func saveMemory(note: String, title: String, userId: UUID) async {
        guard !isUploading else {
            logger.notice("Save operation is already in progress.")
            return
        }

        guard isUploadEnabled else {
            errorMessage = "모든 필드를 올바르게 입력해주세요."
            return
        }

        isUploading = true
        uploadStatus = "Preparing upload..."
        
        // 재시도 로직 변수
        let maxRetries = 3
        var currentRetry = 0
        var lastError: Error?

        do {
            uploadStatus = "Loading video data..."
            guard let videoItem = selectedVideoItem,
                  let videoData = try await videoItem.loadTransferable(type: Data.self) else {
                errorMessage = "Failed to load video data."
                // 실패 시 상태 초기화
                isUploading = false
                uploadStatus = ""
                return
            }

            // 재시도 로직으로 메모리 업로드 시도
            while currentRetry < maxRetries {
                do {
                    // 상태별 메시지 업데이트
                    if currentRetry == 0 {
                        uploadStatus = "Uploading files..."
                    } else {
                        uploadStatus = "Retrying... (\(currentRetry)/\(maxRetries-1))"
                    }
                    
                    let memory = try await createMemoryUseCase.execute(
                        note: note,
                        title: title,
                        category: selectedCategory!,
                        videoData: videoData,
                        thumbnailImage: thumbnailImage!,
                        userId: userId
                    )

                    uploadStatus = "Upload Success"
                    print("🔍 Memory upload successful, setting lastUploadedMemory")
                    print("✅ Uploaded memory ID: \(memory.id.uuidString)")
                    print("✅ Uploaded memory title: \(memory.title)")
                    print("✅ Uploaded memory note: \(memory.note)")
                    print("✅ Uploaded memory category: \(memory.category)")
                    
                    lastUploadedMemory = memory
                    print("✅ lastUploadedMemory successfully set")
                    
                    // 성공 시 상태 초기화
                    isUploading = false
                    uploadStatus = ""
                    return
                    
                } catch {
                    lastError = error
                    currentRetry += 1
                    
                    // 네트워크 오류인 경우에만 재시도
                    if isNetworkError(error) && currentRetry < maxRetries {
                        uploadStatus = "Connection lost, retrying... (\(currentRetry)/\(maxRetries-1))"
                        
                        // 지수 백오프로 지연
                        let delay = min(pow(2.0, Double(currentRetry)), 8.0)
                        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                        continue
                    } else {
                        throw error
                    }
                }
            }
            
            // 최대 재시도 횟수 초과
            if let lastError = lastError {
                throw lastError
            }
            
        } catch {
            uploadStatus = ""
            logger.error("Memory upload failed: \(error.localizedDescription)")
            
            // 사용자 친화적 에러 메시지와 팝업
            let userFriendlyMessage: String
            if isNetworkError(error) {
                userFriendlyMessage = "Network connection issue occurred.\nPlease check your internet connection and try again."
            } else {
                userFriendlyMessage = "An error occurred during upload.\nPlease try again in a moment."
            }
            
            // 에러 팝업 표시
            popupData = PopupData(
                title: "Upload Failed",
                notes: userFriendlyMessage,
                leadingButtonText: "",
                trailingButtonText: "OK",
                buttonImageString: "xmark",
                circularAction: { [weak self] in
                    self?.popupData = nil
                },
                leadingButtonAction: nil,
                trailingButtonAction: { [weak self] in
                    self?.popupData = nil
                }
            )
            
            errorMessage = userFriendlyMessage
            
            // 실패 시 상태 초기화  
            isUploading = false
            uploadStatus = ""
        }
    }
    
    // 네트워크 오류 판별 함수
    private func isNetworkError(_ error: Error) -> Bool {
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost, .timedOut, .cannotConnectToHost, .cannotFindHost, .dnsLookupFailed:
                return true
            default:
                return false
            }
        }
        
        if let nsError = error as NSError? {
            // NSURLError 도메인 체크
            if nsError.domain == NSURLErrorDomain {
                switch nsError.code {
                case NSURLErrorNotConnectedToInternet, NSURLErrorNetworkConnectionLost, NSURLErrorTimedOut, NSURLErrorCannotConnectToHost, NSURLErrorCannotFindHost, NSURLErrorDNSLookupFailed:
                    return true
                default:
                    return false
                }
            }
        }
        
        return false
    }
    
    func handleViewDisappearance() {
        resetVideoData()
        isPickerBlocked = true
    }
    
    func toggleCategory(_ category: Category) {
        selectedCategory = (selectedCategory == category) ? nil : category
    }
    
    func showPhotosPickerPopup(dismissWindow: @escaping () -> Void) {
        popupData = PopupData(
            title: "Notice",
            notes: "Currently, only videos under 1GB can be uploaded.\n(Approximately 5 minutes of spatial video)",
            leadingButtonText: "Cancel",
            trailingButtonText: "Continue",
            buttonImageString: "xmark",
            circularAction: { [weak self] in
                self?.popupData = nil
                self?.isPickerBlocked = true
            },
            leadingButtonAction: { [weak self] in
                self?.popupData = nil
                self?.isPickerBlocked = true
                dismissWindow()
            },
            trailingButtonAction: { [weak self] in
                self?.popupData = nil
                self?.isPickerBlocked = false
            }
        )
    }
    
    private func resetVideoData() {
        thumbnailImage = nil
        errorMessage = nil
        selectedCategory = nil
        selectedVideoItem = nil
        title = ""
        note = ""
    }
    
    func handleVideoSelection(item: PhotosPickerItem?) {
        logger.notice("handleVideoSelection called with item: \(item != nil ? "not nil" : "nil")")
        
        guard let item = item else {
            logger.notice("No video item selected.")
            return
        }

        logger.notice("Starting thumbnail generation for selected video")
        isThumbnailGenerating = true
        
        Task { [weak self] in
            await self?.processVideoSelection(item: item)
        }
    }
    
    private func processVideoSelection(item: PhotosPickerItem) async {
        do {
            guard let videoData = try await item.loadTransferable(type: Data.self) else {
                throw NSError(domain: "Thumbnail Error", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not load video data."])
            }
            
            // Check file size with detailed logging
            let fileSize = Int64(videoData.count)
            logger.notice("Checking file size: \(fileSize) bytes (Max: \(self.MAX_FILE_SIZE) bytes)")
            
            if fileSize >= MAX_FILE_SIZE {
                logger.error("File size (\(self.formatFileSize(fileSize))) exceeds limit of 1GB")
                
                await MainActor.run { [weak self] in
                    guard let self = self else { return }
                    self.selectedVideoItem = nil  // Reset selection
                    
                    // Show error popup instead of just setting error message
                    self.popupData = PopupData(
                        title: "File Size Exceeded",
                        notes: "Your video file (\(self.formatFileSize(fileSize))) is too large.\nPlease choose a video under 1GB.",
                        leadingButtonText: "",
                        trailingButtonText: "OK",
                        buttonImageString: "xmark",
                        circularAction: { [weak self] in
                            self?.popupData = nil
                            self?.isPickerBlocked = false
                        },
                        leadingButtonAction: nil,
                        trailingButtonAction: { [weak self] in
                            self?.popupData = nil
                            self?.isPickerBlocked = false
                        }
                    )
                    
                    self.setThumbnailGeneratingFalseWithDelay()
                }
                return
            }
            
            // Format file size for display and update UI on main thread
            await MainActor.run { [weak self] in
                guard let self = self else { return }
                self.uploadingFileSize = self.formatFileSize(fileSize)
                self.logger.notice("File size accepted: \(self.uploadingFileSize)")
            }

            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).mov")
            try videoData.write(to: tempURL)
            logger.notice("Video data saved to temporary URL.")

            let thumbnail = await generateThumbnail(from: tempURL)
            
            // Clean up temp file
            try? FileManager.default.removeItem(at: tempURL)
            
            await MainActor.run { [weak self] in
                guard let self = self else { return }
                
                if let thumbnail = thumbnail {
                    self.thumbnailImage = thumbnail
                    self.selectedVideoItem = item  // Only set video item if thumbnail generation succeeds
                    let size = thumbnail.size
                    self.logger.notice("Thumbnail set successfully. Image size: \(size.width)x\(size.height)")
                } else {
                    self.errorMessage = "썸네일 추출에 실패했습니다."
                    self.selectedVideoItem = nil  // Reset if thumbnail generation fails
                    self.logger.error("Thumbnail generation failed - thumbnail is nil")
                }
                self.setThumbnailGeneratingFalseWithDelay()
            }
        } catch {
            await MainActor.run { [weak self] in
                guard let self = self else { return }
                self.errorMessage = "Video loading failed: \(error.localizedDescription)"
                self.logger.error("Video selection error: \(error.localizedDescription)")
                self.isPickerBlocked = false
                self.setThumbnailGeneratingFalseWithDelay()
            }
        }
    }

    private func setThumbnailGeneratingFalseWithDelay() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.isThumbnailGenerating = false
        }
    }

    private func generateThumbnail(from url: URL) async -> UIImage? {
        let asset = AVURLAsset(url: url)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        imageGenerator.maximumSize = CGSize(width: 1920, height: 1080)
        
        // Try multiple time points sequentially instead of nested async calls
        let timePoints = [
            CMTime(seconds: 2.0, preferredTimescale: 600),
            CMTime(seconds: 1.0, preferredTimescale: 600),
            CMTime(seconds: 0.5, preferredTimescale: 600),
            CMTime.zero
        ]
        
        for timePoint in timePoints {
            do {
                let cgImage = try await withCheckedThrowingContinuation { [weak self] continuation in
                    var hasResumed = false
                    
                    imageGenerator.generateCGImagesAsynchronously(forTimes: [NSValue(time: timePoint)]) { _, cgImage, _, result, error in
                        // Prevent multiple continuations
                        guard !hasResumed else { return }
                        hasResumed = true
                        
                        if let cgImage = cgImage, result == .succeeded {
                            self?.logger.notice("Thumbnail generated successfully at time \(timePoint.seconds)s")
                            continuation.resume(returning: cgImage)
                        } else {
                            let errorMsg = error?.localizedDescription ?? "Unknown error"
                            self?.logger.warning("Failed to generate thumbnail at time \(timePoint.seconds)s: \(errorMsg)")
                            continuation.resume(throwing: error ?? NSError(domain: "ThumbnailError", code: -1))
                        }
                    }
                    
                    // Timeout after 10 seconds
                    DispatchQueue.global().asyncAfter(deadline: .now() + 10) {
                        guard !hasResumed else { return }
                        hasResumed = true
                        self?.logger.warning("Thumbnail generation timeout at time \(timePoint.seconds)s")
                        continuation.resume(throwing: NSError(domain: "ThumbnailError", code: -2, userInfo: [NSLocalizedDescriptionKey: "Timeout"]))
                    }
                }
                
                let thumbnail = UIImage(cgImage: cgImage)
                logger.notice("Thumbnail created successfully from CGImage")
                return thumbnail
                
            } catch {
                logger.warning("Thumbnail generation failed at time \(timePoint.seconds)s: \(error.localizedDescription)")
                continue
            }
        }
        
        logger.error("All thumbnail generation attempts failed")
        return nil
    }
    
    private func checkPlayerReadyStatus(for playerItem: AVPlayerItem) async -> Bool {
        await withCheckedContinuation { continuation in
            let lockQueue = DispatchQueue(label: "checkPlayerReadyStatus.lock")
            var hasResumed = false
            var observer: NSKeyValueObservation? // 옵셔널로 선언

            // 상태 관찰
            observer = playerItem.observe(\.status, options: [.new]) { [weak self] item, _ in
                lockQueue.sync {
                    guard !hasResumed else { return } // 이미 완료된 경우 무시
                    hasResumed = true
                    observer?.invalidate() // Observer 해제
                    observer = nil // 메모리 관리
                    if item.status == .readyToPlay {
                        self?.logger.notice("Player item is ready to play.")
                        continuation.resume(returning: true)
                    } else if item.status == .failed {
                        self?.logger.error("Player item failed to load: \(item.error?.localizedDescription ?? "Unknown error").")
                        continuation.resume(returning: false)
                    }
                }
            }

            // 5초 타이머 설정
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
                lockQueue.sync {
                    guard !hasResumed else { return } // 이미 완료된 경우 무시
                    hasResumed = true
                    observer?.invalidate() // Observer 해제
                    observer = nil // 메모리 관리
                    self?.logger.warning("Player item did not become ready within timeout.")
                    continuation.resume(returning: false)
                }
            }
        }
    }

    private func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
    
    func getLastUploadedMemory() -> Memory? {
        print("🔍 getLastUploadedMemory() called")
        print("🔍 lastUploadedMemory state: \(String(describing: lastUploadedMemory))")
        if let memory = lastUploadedMemory {
            print("🔍 Returning memory with ID: \(memory.id.uuidString)")
            print("🔍 Memory title: \(memory.title)")
        } else {
            print("❌ lastUploadedMemory is nil")
        }
        return lastUploadedMemory
    }
}
