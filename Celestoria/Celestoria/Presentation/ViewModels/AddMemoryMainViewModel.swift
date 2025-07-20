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
        defer { isUploading = false }

        do {
            guard let videoItem = selectedVideoItem,
                  let videoData = try await videoItem.loadTransferable(type: Data.self) else {
                errorMessage = "비디오 데이터를 불러올 수 없습니다."
                return
            }

            let memory = try await createMemoryUseCase.execute(
                note: note,
                title: title,
                category: selectedCategory!,
                videoData: videoData,
                thumbnailImage: thumbnailImage!,
                userId: userId
            )

            lastUploadedMemory = memory
            logger.notice("Memory uploaded successfully: \(memory.id)")
        } catch {
            errorMessage = error.localizedDescription
        }
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
        
        Task {
            await self.processVideoSelection(item: item)
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
                    selectedVideoItem = nil  // Reset selection
                    
                    // Show error popup instead of just setting error message
                    popupData = PopupData(
                        title: "File Size Exceeded",
                        notes: "Your video file (\(formatFileSize(fileSize))) is too large.\nPlease choose a video under 1GB.",
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
                    
                    setThumbnailGeneratingFalseWithDelay()
                    return
                }
                
                // Format file size for display
                uploadingFileSize = formatFileSize(fileSize)
                logger.notice("File size accepted: \(self.uploadingFileSize)")

                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).mov")
                try videoData.write(to: tempURL)
                logger.notice("Video data saved to temporary URL.")

                let thumbnail = await generateThumbnail(from: tempURL)
                
                if let thumbnail = thumbnail {
                    self.thumbnailImage = thumbnail
                    let size = thumbnail.size
                    self.logger.notice("Thumbnail set successfully. Image size: \(size.width)x\(size.height)")
                } else {
                    self.errorMessage = "썸네일 추출에 실패했습니다."
                    self.logger.error("Thumbnail generation failed - thumbnail is nil")
                }
                self.setThumbnailGeneratingFalseWithDelay()
            } catch {
                errorMessage = "Video loading failed: \(error.localizedDescription)"
                logger.error("Video selection error: \(error.localizedDescription)")
                isPickerBlocked = false
                setThumbnailGeneratingFalseWithDelay()
            }
    }

    private func setThumbnailGeneratingFalseWithDelay() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.isThumbnailGenerating = false
        }
    }

    private func generateThumbnail(from url: URL) async -> UIImage? {
        let asset = AVURLAsset(url: url)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        imageGenerator.maximumSize = CGSize(width: 1920, height: 1080)
        
        let time = CMTime(seconds: 2.0, preferredTimescale: 600)
        
        do {
            return try await withCheckedThrowingContinuation { continuation in
                imageGenerator.generateCGImagesAsynchronously(forTimes: [NSValue(time: time)]) { _, cgImage, _, result, error in
                    if let cgImage = cgImage, result == .succeeded {
                        let thumbnail = UIImage(cgImage: cgImage)
                        self.logger.notice("Thumbnail generated successfully using AVAssetImageGenerator.")
                        continuation.resume(returning: thumbnail)
                    } else if let error = error {
                        self.logger.error("Failed to generate thumbnail: \(error.localizedDescription)")
                        
                        // Fallback: Try to get the first frame
                        let firstFrameTime = CMTime(seconds: 0.0, preferredTimescale: 600)
                        imageGenerator.generateCGImagesAsynchronously(forTimes: [NSValue(time: firstFrameTime)]) { _, cgImage, _, result, error in
                            if let cgImage = cgImage, result == .succeeded {
                                let thumbnail = UIImage(cgImage: cgImage)
                                self.logger.notice("Thumbnail generated successfully from first frame.")
                                continuation.resume(returning: thumbnail)
                            } else {
                                self.logger.error("Failed to generate thumbnail from first frame: \(error?.localizedDescription ?? "Unknown error")")
                                continuation.resume(returning: nil)
                            }
                        }
                    } else {
                        continuation.resume(returning: nil)
                    }
                }
            }
        } catch {
            logger.error("Failed to generate thumbnail: \(error.localizedDescription)")
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
        return lastUploadedMemory
    }
}
