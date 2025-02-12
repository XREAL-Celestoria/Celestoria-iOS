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
            spatialMetadata: videoUploadResult.metadata,
            isHidden: false
        )

        // 메모리 저장
        try await memoryRepository.createMemory(memory)

        return memory
    }

    // 랜덤 위치 생성 (중복된 로직 분리)
    private func generateRandomPosition() -> Memory.Position {
        let radius: Double = 8.0
        let yMin: Double = -2.0
        let yMax: Double = 5.0
        
        // y를 [-2, 5] 사이에서 무작위로 선택
        let y = Double.random(in: yMin...yMax)
        
        // 주어진 y에 대해, 원의 수평 반지름(h)은 피타고라스 정리에 따라 계산됩니다.
        let horizontalRadius = sqrt((radius * radius) - (y * y))
        
        // 수평원(x-z 평면)에서, 앞쪽(즉, z가 음수인 반원)만 선택하기 위해, 
        // 각도 alpha를 -π (180°)에서 0 (0°) 사이에서 선택합니다.
        let alpha = Double.random(in: -Double.pi...0)
        
        let x = horizontalRadius * cos(alpha)
        let z = horizontalRadius * sin(alpha)  // sin(alpha)가 음수이므로, z는 항상 음수가 됨.
        
        return Memory.Position(x: x, y: y, z: z)
    }
}
