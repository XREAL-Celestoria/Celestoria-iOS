//
//  CreateMemoryUseCase.swift
//  Celestoria
//
//  Created by Park Seyoung on 1/20/25.
//

import Foundation
import UIKit

class CreateMemoryUseCase {
    private let memoryRepository: MemoryRepository
    private let mediaRepository: MediaRepository

    init(memoryRepository: MemoryRepository, mediaRepository: MediaRepository) {
        self.memoryRepository = memoryRepository
        self.mediaRepository = mediaRepository
    }

    func execute(
        note: String,
        title: String,
        category: Category,
        videoData: Data,
        thumbnailImage: UIImage?,
        userId: UUID
    ) async throws -> Memory {
        // 비디오 업로드
        let videoUploadResult = try await mediaRepository.uploadVideo(data: videoData, userId: userId)

        // 썸네일 업로드 (옵션 처리)
        var thumbnailURL: String = ""
        if let thumbnailImage = thumbnailImage {
            thumbnailURL = try await mediaRepository.uploadThumbnail(image: thumbnailImage, userId: userId)
        }

        // 메모리 객체 생성
        let memory = Memory(
            id: UUID(),
            userId: userId,
            category: category,
            title: title,
            note: note,
            createdAt: Date(),
            position: generateRandomPosition(),
            videoURL: videoUploadResult.url,
            thumbnailURL: thumbnailURL,
            spatialMetadata: videoUploadResult.metadata
        )

        // 메모리 저장
        try await memoryRepository.createMemory(memory)

        return memory
    }

    // 랜덤 위치 생성 (중복된 로직 분리)
    private func generateRandomPosition() -> Memory.Position {
        return Memory.Position(
            x: Double.random(in: Bool.random() ? -5...(-1) : 1...5),
            y: Double.random(in: -1...3),
            z: Double.random(in: Bool.random() ? -5...(-1) : 1...5)
        )
    }
}
