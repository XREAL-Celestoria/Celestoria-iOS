//
//  DeleteMemoryUseCase.swift
//  Celestoria
//
//  Created by Park Seyoung on 1/20/25.
//

import Foundation

class DeleteMemoryUseCase {
    private let memoryRepository: MemoryRepository

    init(memoryRepository: MemoryRepository) {
        self.memoryRepository = memoryRepository
    }

    func execute(memoryId: UUID, videoPath: String?, thumbnailPath: String?) async throws {
        // 데이터베이스에서 메모리 삭제
        try await memoryRepository.deleteMemory(memoryId)

        // 비디오 파일 삭제
        if let videoPath = videoPath {
            try await memoryRepository.deleteStorageFile(bucketName: "spatial_videos", path: videoPath)
        }

        // 썸네일 파일 삭제
        if let thumbnailPath = thumbnailPath {
            try await memoryRepository.deleteStorageFile(bucketName: "thumbnails", path: thumbnailPath)
        }
    }
}

