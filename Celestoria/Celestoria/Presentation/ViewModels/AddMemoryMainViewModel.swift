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
import MetalKit
import CoreImage
import os

@MainActor
class AddMemoryMainViewModel: ObservableObject {
    private let createMemoryUseCase: CreateMemoryUseCase
    private let appModel: AppModel
    
    @Published var popupData: PopupData?
    @Published var isPickerBlocked = true
    @Published var isThumbnailGenerating: Bool = false
    @Published var errorMessage: String?
    @Published var selectedCategory: Category?
    @Published var selectedVideoItem: PhotosPickerItem? {
        didSet {
            if selectedVideoItem != nil {
                handleVideoSelection(item: selectedVideoItem)
            }
        }
    }
    @Published private(set) var lastUploadedMemory: Memory?
    @Published var thumbnailImage: UIImage?
    @Published var isUploading = false
    
    @Published var title: String = ""
    @Published var note: String = ""
    
    var isUploadEnabled: Bool {
        selectedVideoItem != nil &&
        thumbnailImage != nil &&
        selectedCategory != nil &&
        !title.trimmingCharacters(in: .whitespaces).isEmpty &&
        !note.trimmingCharacters(in: .whitespaces).isEmpty &&
        note.count <= 500
    }
    
    init(createMemoryUseCase: CreateMemoryUseCase, appModel: AppModel) {
        self.createMemoryUseCase = createMemoryUseCase
        self.appModel = appModel
    }
    
    func saveMemory(note: String, title: String, userId: UUID) async {
        guard !isUploading else {
            os.Logger.info("Save operation is already in progress.")
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
            os.Logger.info("Memory uploaded successfully: \(memory)")
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
            notes: "Currently, only videos under 5 minutes can be uploaded.\nWould you like to continue adding memory star?",
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
        guard let item = item else {
            os.Logger.info("No video item selected.")
            return
        }

        isThumbnailGenerating = true
        Task {
            do {
                guard let videoData = try await item.loadTransferable(type: Data.self) else {
                    throw NSError(domain: "Thumbnail Error", code: -1, userInfo: [NSLocalizedDescriptionKey: "비디오 데이터를 불러올 수 없습니다."])
                }

                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).mov")
                try videoData.write(to: tempURL)
                os.Logger.info("Video data saved to temporary URL.")

                await generateThumbnail(from: tempURL) { [weak self] thumbnail in
                    guard let self = self else { return }
                    if let thumbnail = thumbnail {
                        self.thumbnailImage = thumbnail
                        os.Logger.info("Thumbnail set successfully.")
                    } else {
                        self.errorMessage = "썸네일 추출에 실패했습니다."
                        os.Logger.error("Thumbnail generation failed.")
                    }
                    self.setThumbnailGeneratingFalseWithDelay()
                }
            } catch {
                errorMessage = "비디오 로드 실패: \(error.localizedDescription)"
                os.Logger.error("Video selection error: \(error.localizedDescription)")
                isPickerBlocked = false
                setThumbnailGeneratingFalseWithDelay()
            }
        }
    }

    private func setThumbnailGeneratingFalseWithDelay() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.isThumbnailGenerating = false
        }
    }

    private func generateThumbnail(from url: URL, completion: @escaping (UIImage?) -> Void) async {
        let asset = AVAsset(url: url)
        let playerItem = AVPlayerItem(asset: asset)
        let videoOutput = AVPlayerItemVideoOutput(pixelBufferAttributes: [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ])
        playerItem.add(videoOutput)

        let player = AVPlayer(playerItem: playerItem)
        player.isMuted = true

        // 1. 플레이어 준비 상태 확인
        let isReady = await checkPlayerReadyStatus(for: playerItem)
        guard isReady else {
            os.Logger.error("Player item is not ready to play.")
            completion(nil)
            return
        }

        // 2. 썸네일 추출 시도
        let maxRetries = 3
        for attempt in 1...maxRetries {
            os.Logger.info("Attempt \(attempt): Extracting pixel buffer for thumbnail.")
            
            let currentTime = CMTime(seconds: 2.0, preferredTimescale: 600)
            if videoOutput.hasNewPixelBuffer(forItemTime: currentTime),
               let pixelBuffer = videoOutput.copyPixelBuffer(forItemTime: currentTime, itemTimeForDisplay: nil) {
                
                // 3. CIContext 변환 및 썸네일 생성
                let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
                let context = CIContext()
                if let cgImage = context.createCGImage(ciImage, from: ciImage.extent) {
                    let thumbnail = UIImage(cgImage: cgImage)
                    os.Logger.info("Thumbnail generated successfully.")
                    completion(thumbnail)
                    return
                } else {
                    os.Logger.error("Failed to convert pixel buffer to UIImage.")
                }
            } else {
                os.Logger.warning("No new pixel buffer available at time: \(currentTime.seconds). Retrying...")
            }

            // 재시도 전 대기
            await Task.sleep(500_000_000) // 0.5초 대기
        }

        os.Logger.error("Failed to generate thumbnail after \(maxRetries) attempts.")
        completion(nil)
    }
    
    private func checkPlayerReadyStatus(for playerItem: AVPlayerItem) async -> Bool {
        await withCheckedContinuation { continuation in
            let lockQueue = DispatchQueue(label: "checkPlayerReadyStatus.lock")
            var hasResumed = false
            var observer: NSKeyValueObservation? // 옵셔널로 선언

            // 상태 관찰
            observer = playerItem.observe(\.status, options: [.new]) { item, _ in
                lockQueue.sync {
                    guard !hasResumed else { return } // 이미 완료된 경우 무시
                    hasResumed = true
                    observer?.invalidate() // Observer 해제
                    observer = nil // 메모리 관리
                    if item.status == .readyToPlay {
                        os.Logger.info("Player item is ready to play.")
                        continuation.resume(returning: true)
                    } else if item.status == .failed {
                        os.Logger.error("Player item failed to load: \(item.error?.localizedDescription ?? "Unknown error").")
                        continuation.resume(returning: false)
                    }
                }
            }

            // 5초 타이머 설정
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                lockQueue.sync {
                    guard !hasResumed else { return } // 이미 완료된 경우 무시
                    hasResumed = true
                    observer?.invalidate() // Observer 해제
                    observer = nil // 메모리 관리
                    os.Logger.warning("Player item did not become ready within timeout.")
                    continuation.resume(returning: false)
                }
            }
        }
    }
    func getLastUploadedMemory() -> Memory? {
        return lastUploadedMemory
    }
}
