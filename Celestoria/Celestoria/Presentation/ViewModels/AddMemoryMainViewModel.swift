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
    @Published var showSuccessAlert = false
    @Published var errorMessage: String?
    @Published var selectedCategory: Category?
    @Published var selectedVideoItem: PhotosPickerItem? {
            didSet {
                // 선택된 비디오가 변경될 때 처리
                resetVideoData() // 기존 데이터 초기화
                handleVideoSelection(item: selectedVideoItem)
            }
        }
    
    @Published var thumbnailImage: UIImage?
    @Published var isUploading = false
    
    @Published var title: String = ""
    @Published var note: String = ""
    
    var isUploadEnabled: Bool {
        return selectedVideoItem != nil &&
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
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "타이틀을 입력해주세요."
            return
        }
        
        guard let videoItem = selectedVideoItem else {
            errorMessage = "비디오를 선택해주세요."
            return
        }
        
        guard let category = selectedCategory else {
            errorMessage = "카테고리를 선택해주세요."
            return
        }
        
        isUploading = true // 업로드 시작 상태 표시
        defer { // 작업 종료 후 반드시 실행
            isUploading = false
        }
        
        do {
            // 비디오 데이터 로드
            guard let videoData = try await videoItem.loadTransferable(type: Data.self) else {
                errorMessage = "비디오 데이터를 불러올 수 없습니다."
                return
            }
            
            // 메모리 생성 실행
            let memory = try await createMemoryUseCase.execute(
                note: note,
                title: title,
                category: category,
                videoData: videoData,
                thumbnailImage: thumbnailImage,
                userId: userId
            )
            
            showSuccessAlert = true
            print("메모리 생성 완료: \(memory)")
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func handleViewDisappearance() {
        selectedVideoItem = nil
        isPickerBlocked = true
        resetVideoData()
    }
    
    func toggleCategory(_ category: Category) {
        if selectedCategory == category {
            selectedCategory = nil
        } else {
            os.Logger.info("\(category) is selected")
            selectedCategory = category
        }
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
                self?.appModel.showAddMemoryView = false
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
//        selectedVideoItem = nil
        thumbnailImage = nil
        errorMessage = nil
        selectedCategory = nil
        title = ""
        note = ""
    }

    
    func handleVideoSelection(item: PhotosPickerItem?) {
        guard let item = item else {
            os.Logger.info("No video item selected.")
            return
        }

        Task {
            do {
                os.Logger.info("Attempting to load video data from selected item.")
                guard let videoData = try await item.loadTransferable(type: Data.self) else {
                    os.Logger.error("Unable to load video data from PhotosPickerItem.")
                    errorMessage = "비디오 데이터를 불러올 수 없습니다."
                    return
                }

                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).mov")
                try videoData.write(to: tempURL)
                os.Logger.info("Video data written to temporary URL: \(tempURL)")

                generateThumbnailWithVideoOutput(from: tempURL) { [weak self] thumbnail in
                    guard let self = self else { return }
                    if let thumbnail = thumbnail {
                        os.Logger.info("Thumbnail successfully generated.")
                        DispatchQueue.main.async {
                            self.thumbnailImage = thumbnail
                            self.isPickerBlocked = false
                        }
                    } else {
                        os.Logger.error("Failed to generate thumbnail.")
                        DispatchQueue.main.async {
                            self.errorMessage = "썸네일 생성에 실패했습니다."
                            self.isPickerBlocked = false
                        }
                    }
                }
            } catch {
                os.Logger.error("Failed to process video selection. \(error.localizedDescription)")
                errorMessage = "Failed to load video: \(error.localizedDescription)"
            }
        }
    }

    func generateThumbnailWithVideoOutput(from url: URL, completion: @escaping (UIImage?) -> Void) {
        os.Logger.info("Starting thumbnail generation using AVPlayerItemVideoOutput.")
        
        let asset = AVAsset(url: url)
        let playerItem = AVPlayerItem(asset: asset)
        
        let videoOutput = AVPlayerItemVideoOutput(pixelBufferAttributes: [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ])
        playerItem.add(videoOutput)
        
        let player = AVPlayer(playerItem: playerItem)
        player.play()
        
        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 1.0) { // 1초 후 프레임 추출
            let currentTime = player.currentItem?.currentTime() ?? CMTime(seconds: 1.5, preferredTimescale: 600)
            os.Logger.info("Checking for new pixel buffer at time: \(currentTime.seconds) seconds.")
            
            guard videoOutput.hasNewPixelBuffer(forItemTime: currentTime),
                  let pixelBuffer = videoOutput.copyPixelBuffer(forItemTime: currentTime, itemTimeForDisplay: nil) else {
                os.Logger.error("Failed to extract pixel buffer for thumbnail.")
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            // PixelBuffer를 UIImage로 변환
            let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
            let context = CIContext()
            if let cgImage = context.createCGImage(ciImage, from: ciImage.extent) {
                let thumbnail = UIImage(cgImage: cgImage)
                os.Logger.info("Thumbnail successfully created.")
                DispatchQueue.main.async {
                    completion(thumbnail)
                }
            } else {
                os.Logger.error("Failed to generate thumbnail from pixel buffer.")
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }
    }
    
    private func extractPixelBuffer(videoOutput: AVPlayerItemVideoOutput, player: AVPlayer, completion: @escaping (UIImage?) -> Void) {
        let currentTime = player.currentItem?.currentTime() ?? CMTime(seconds: 1.0, preferredTimescale: 600)
        os.Logger.info("Checking for new pixel buffer at time: \(currentTime.seconds) seconds.")
        
        guard videoOutput.hasNewPixelBuffer(forItemTime: currentTime),
              let pixelBuffer = videoOutput.copyPixelBuffer(forItemTime: currentTime, itemTimeForDisplay: nil) else {
            os.Logger.error("Failed to extract pixel buffer for thumbnail. Retrying...")
            DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 0.5) {
                self.extractPixelBuffer(videoOutput: videoOutput, player: player, completion: completion)
            }
            return
        }
        
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext()
        if let cgImage = context.createCGImage(ciImage, from: ciImage.extent) {
            let thumbnail = UIImage(cgImage: cgImage)
            os.Logger.info("Thumbnail successfully created.")
            DispatchQueue.main.async {
                completion(thumbnail)
            }
        } else {
            os.Logger.error("Failed to generate thumbnail from pixel buffer.")
            DispatchQueue.main.async {
                completion(nil)
            }
        }
    }
}
