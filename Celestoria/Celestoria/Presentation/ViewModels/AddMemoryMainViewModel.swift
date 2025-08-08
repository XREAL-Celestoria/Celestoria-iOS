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
    
    // 중복 처리 방지를 위한 변수
    private var currentProcessingItem: PhotosPickerItem?
    
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
                        userId: userId,
                        progressCallback: { [weak self] progress, message in
                            Task { @MainActor in
                                self?.uploadProgress = progress
                                self?.uploadStatus = message
                                
                                // 상세한 진행률 로깅
                                let percentage = Int(progress * 100)
                                self?.logger.info("📊 업로드 진행률: \(percentage)% - \(message)")
                            }
                        }
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
                    // 업로드 상태도 함께 리셋
                    self?.isUploading = false
                    self?.uploadProgress = 0
                    self?.uploadStatus = ""
                    self?.uploadingFileSize = ""
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
                // 업로드 상태도 함께 리셋
                self?.isUploading = false
                self?.uploadProgress = 0
                self?.uploadStatus = ""
                self?.uploadingFileSize = ""
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
        currentProcessingItem = nil // 현재 처리 중인 아이템도 초기화
    }
    
    func handleVideoSelection(item: PhotosPickerItem?) {
        logger.notice("handleVideoSelection called with item: \(item != nil ? "not nil" : "nil")")
        
        guard let item = item else {
            logger.notice("No video item selected.")
            currentProcessingItem = nil // 선택이 해제되면 현재 처리 중인 아이템도 초기화
            return
        }

        // 중복 처리 방지: 이미 같은 아이템을 처리 중이면 무시
        if currentProcessingItem == item {
            logger.notice("Same video item is already being processed, ignoring duplicate call")
            return
        }
        
        // 현재 처리 중인 아이템 업데이트
        currentProcessingItem = item

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
                            // 업로드 상태도 함께 리셋
                            self?.isUploading = false
                            self?.uploadProgress = 0
                            self?.uploadStatus = ""
                            self?.uploadingFileSize = ""
                        }
                    )
                    
                    // 파일 크기 초과 시에도 현재 처리 중인 아이템 초기화
                    self.currentProcessingItem = nil
                    self.setThumbnailGeneratingComplete()
                }
                return
            }
            
            // Format file size for display and update UI on main thread
            await MainActor.run { [weak self] in
                guard let self = self else { return }
                self.uploadingFileSize = self.formatFileSize(fileSize)
                self.logger.notice("File size accepted: \(self.uploadingFileSize)")
            }

            // 썸네일 생성 최적화 - 새로운 고속 메서드 사용
            logger.notice("최적화된 썸네일 생성 시작")
            let thumbnail = await generateThumbnailFromData(videoData)
            
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
                
                // 처리 완료 후 현재 처리 중인 아이템 초기화
                self.currentProcessingItem = nil
                self.setThumbnailGeneratingComplete()
            }
        } catch {
            await MainActor.run { [weak self] in
                guard let self = self else { return }
                self.errorMessage = "Video loading failed: \(error.localizedDescription)"
                self.logger.error("Video selection error: \(error.localizedDescription)")
                self.isPickerBlocked = false
                
                // 에러 발생 시에도 현재 처리 중인 아이템 초기화
                self.currentProcessingItem = nil
                self.setThumbnailGeneratingComplete()
            }
        }
    }

    private func setThumbnailGeneratingComplete() {
        // 썸네일 생성 완료 즉시 로딩뷰 숨김
        DispatchQueue.main.async { [weak self] in
            self?.isThumbnailGenerating = false
        }
    }

    private func generateThumbnail(from url: URL) async -> UIImage? {
        logger.notice("🚀 레거시 썸네일 함수 - 최적화 적용")
        let startTime = Date()
        
        let asset = AVURLAsset(url: url, options: [
            AVURLAssetPreferPreciseDurationAndTimingKey: false // 속도 우선
        ])
        
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        
        // ⚡ 최적화: 400px로 크기 제한 (기존 1920x1080 → 400x400)
        imageGenerator.maximumSize = CGSize(width: 400, height: 400)
        
        // ⚡ 속도 최적화: 허용 오차 확대
        imageGenerator.requestedTimeToleranceBefore = CMTime(seconds: 2, preferredTimescale: 600)
        imageGenerator.requestedTimeToleranceAfter = CMTime(seconds: 2, preferredTimescale: 600)
        
        // ⚡ 동기식으로 빠르게 처리 (비동기 → 동기)
        do {
            let timePoint = CMTime(seconds: 1.0, preferredTimescale: 600)
            #if os(visionOS)
            // visionOS에서는 비동기 방식 사용
            let (cgImage, _) = try await imageGenerator.image(at: timePoint)
            #else
            // iOS에서는 동기 방식 사용
            let cgImage = try imageGenerator.copyCGImage(at: timePoint, actualTime: nil)
            #endif
            let thumbnail = UIImage(cgImage: cgImage)
            
            let duration = Date().timeIntervalSince(startTime)
            logger.notice("🎯 레거시 썸네일 생성 성공 - 소요시간: \(String(format: "%.3f", duration))초")
            return thumbnail
            
        } catch {
            // 실패 시 0초 지점에서 재시도
            do {
                #if os(visionOS)
                // visionOS에서는 비동기 방식 사용
                let (cgImage, _) = try await imageGenerator.image(at: CMTime.zero)
                #else
                // iOS에서는 동기 방식 사용
                let cgImage = try imageGenerator.copyCGImage(at: CMTime.zero, actualTime: nil)
                #endif
                let thumbnail = UIImage(cgImage: cgImage)
                
                let duration = Date().timeIntervalSince(startTime)
                logger.notice("🎯 레거시 썸네일 생성 성공 (0초) - 소요시간: \(String(format: "%.3f", duration))초")
                return thumbnail
                
            } catch {
                let duration = Date().timeIntervalSince(startTime)
                logger.error("❌ 레거시 썸네일 생성 실패 - 소요시간: \(String(format: "%.3f", duration))초")
                return nil
            }
        }
    }
    
    /// 메모리에서 직접 썸네일 생성 (파일 I/O 최적화)
    private func generateThumbnailFromData(_ videoData: Data) async -> UIImage? {
        logger.notice("메모리에서 썸네일 생성 시작")
        let startTime = Date()
        
        // 임시 파일 생성 (메모리 맵핑 최적화)
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).mov")
        defer {
            try? FileManager.default.removeItem(at: tempURL)
        }
        
        do {
            // 파일 쓰기 최적화
            try videoData.write(to: tempURL, options: .atomic)
            
            // AVAsset 생성 최적화
            let asset = AVURLAsset(url: tempURL, options: [
                AVURLAssetPreferPreciseDurationAndTimingKey: false, // 정밀도 낮춤
                AVURLAssetReferenceRestrictionsKey: AVAssetReferenceRestrictions([]).rawValue
            ])
            
            let imageGenerator = AVAssetImageGenerator(asset: asset)
            imageGenerator.appliesPreferredTrackTransform = true
            imageGenerator.maximumSize = CGSize(width: 400, height: 400)
            
            // 썸네일 품질 vs 속도 최적화
            imageGenerator.requestedTimeToleranceBefore = CMTime(seconds: 2, preferredTimescale: 600)
            imageGenerator.requestedTimeToleranceAfter = CMTime(seconds: 2, preferredTimescale: 600)
            
            // 가장 빠른 동기 방식 사용
            let timePoint = CMTime(seconds: 1.0, preferredTimescale: 600)
            #if os(visionOS)
            // visionOS에서는 비동기 방식 사용
            let (cgImage, _) = try await imageGenerator.image(at: timePoint)
            #else
            // iOS에서는 동기 방식 사용
            let cgImage = try imageGenerator.copyCGImage(at: timePoint, actualTime: nil)
            #endif
            
            let thumbnail = UIImage(cgImage: cgImage)
            let duration = Date().timeIntervalSince(startTime)
            logger.notice("메모리 썸네일 생성 성공 - 소요시간: \(String(format: "%.3f", duration))초")
            return thumbnail
            
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logger.error("메모리 썸네일 생성 실패 - 소요시간: \(String(format: "%.3f", duration))초, 에러: \(error.localizedDescription)")
            return nil
        }
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
