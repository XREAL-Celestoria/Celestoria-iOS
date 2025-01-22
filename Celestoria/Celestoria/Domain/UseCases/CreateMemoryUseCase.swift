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
    
    func execute(note: String, title: String, category: Category, videoData: Data, thumbnailImage: UIImage?, userId: UUID) async throws -> Memory {
        // 비디오와 썸네일 업로드
        async let uploadVideoTask = mediaRepository.uploadVideo(data: videoData)
        async let uploadThumbnailTask = thumbnailImage != nil ? mediaRepository.uploadThumbnail(image: thumbnailImage!) : nil
        
        let (videoResult, thumbnailResult) = try await (uploadVideoTask, uploadThumbnailTask)
        
        // 비디오 업로드 결과
        let videoURL = videoResult.url
        let metadata = videoResult.metadata
        
        // 썸네일 업로드 결과
        let thumbnailURL = thumbnailResult ?? ""
        
        // 새로운 메모리 생성
        let memory = Memory(
            id: UUID(),
            userId: userId,
            category: category,
            title: title,
            note: note,
            createdAt: Date(),
            position: Memory.Position(
                x: Double.random(in: -5...5),
                y: Double.random(in: -5...5),
                z: Double.random(in: -5...5)
            ),
            videoURL: videoURL,
            thumbnailURL: thumbnailURL,
            spatialMetadata: metadata
        )
        
        // 메모리 저장
        try await memoryRepository.createMemory(memory)
        return memory
    }
}
