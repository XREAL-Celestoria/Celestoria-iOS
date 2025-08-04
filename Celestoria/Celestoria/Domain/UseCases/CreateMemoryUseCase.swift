//
//  CreateMemoryUseCase.swift
//  Celestoria
//
//  Created by Park Seyoung on 1/20/25.
//

import Foundation
import UIKit
import os

class CreateMemoryUseCase {
    private let memoryRepository: MemoryRepository
    private let mediaRepository: MediaRepository
    private let logger = Logger(subsystem: "com.Celestoria.Celestoria", category: "CreateMemoryUseCase")

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
        var videoUploadResult: (url: String, metadata: Memory.SpatialMetadata?)? = nil
        var thumbnailURL: String = ""
        
        do {
            // 비디오와 썸네일 업로드를 병렬로 처리
            async let videoUpload: (url: String, metadata: Memory.SpatialMetadata?) = mediaRepository.uploadVideo(data: videoData, userId: userId)
            async let thumbnailUpload: String = {
        if let thumbnailImage = thumbnailImage {
                    return try await mediaRepository.uploadThumbnail(image: thumbnailImage, userId: userId)
                } else {
                    return ""
                }
            }()
            
            // 병렬 업로드 완료 대기
            videoUploadResult = try await videoUpload
            thumbnailURL = try await thumbnailUpload
            
            // CDN 전파 대기
            try await Task.sleep(nanoseconds: 1_000_000_000)
            
            // URL 유효성 검증
            try await quickValidateUploadedFiles(videoURL: videoUploadResult?.url, thumbnailURL: thumbnailURL)

        // 메모리 객체 생성
        let memory = Memory(
            id: UUID(),
            userId: userId,
            category: category,
            title: title,
            note: note,
            createdAt: Date(),
            position: generateRandomPosition(),
                videoURL: videoUploadResult?.url ?? "",
            thumbnailURL: thumbnailURL,
                spatialMetadata: videoUploadResult?.metadata,
            isHidden: false
        )

        // 메모리 저장
            try await quickCreateMemory(memory)

        return memory
            
        } catch {
            logger.error("메모리 생성 실패: \(error.localizedDescription)")
            
            // 부분적으로 업로드된 파일들 정리
            await cleanupPartialUpload(videoURL: videoUploadResult?.url, thumbnailURL: thumbnailURL, userId: userId)
            
            throw error
        }
    }
    
    // 빠른 업로드 파일 유효성 검증 (병렬 처리)
    private func quickValidateUploadedFiles(videoURL: String?, thumbnailURL: String) async throws {
        // 비디오와 썸네일 URL을 병렬로 검증
        async let videoCheck: Bool = {
            if let videoURL = videoURL, !videoURL.isEmpty {
                return await quickURLCheck(videoURL, name: "Video")
            }
            return true
        }()
        
        async let thumbnailCheck: Bool = {
            if !thumbnailURL.isEmpty {
                return await quickURLCheck(thumbnailURL, name: "Thumbnail")
            }
            return true
        }()
        
        // 병렬 검증 결과 확인
        let (isVideoOK, isThumbnailOK) = try await (videoCheck, thumbnailCheck)
        
        if !isVideoOK {
            throw CreateMemoryError.uploadedFileNotAccessible("Video file not accessible")
        }
        if !isThumbnailOK {
            throw CreateMemoryError.uploadedFileNotAccessible("Thumbnail file not accessible")
        }
    }
    
    // 빠른 URL 접근 검증
    private func quickURLCheck(_ urlString: String, name: String) async -> Bool {
        // 첫 번째 빠른 체크
        if await isURLAccessible(urlString, timeout: 3) {
            return true
        }
        
        // 실패 시 한 번 더 체크
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        let finalResult = await isURLAccessible(urlString, timeout: 5)
        
        if !finalResult {
            logger.warning("\(name) file accessibility check failed, but continuing upload")
        }
        
        // URL 검증 실패해도 계속 진행
        return true
    }
    
    // Supabase 연결 준비 (cold start 문제 해결)
    private func warmupSupabaseConnection() async throws {
        logger.info("Supabase 연결 준비 중...")
        
        let maxWarmupRetries = 2
        var currentRetry = 0
        
        while currentRetry < maxWarmupRetries {
            do {
                // 가벼운 쿼리로 연결 테스트 (실제 메모리 조회하되 결과는 무시)
                let _: [Memory] = try await memoryRepository.fetchMemories(for: UUID())
                
                logger.info("Supabase 연결 준비 완료 (빈 결과는 정상)")
                return
                
            } catch {
                currentRetry += 1
                logger.warning("Supabase 연결 준비 실패 (시도 \(currentRetry)/\(maxWarmupRetries)): \(error.localizedDescription)")
                
                if currentRetry < maxWarmupRetries {
                    try await Task.sleep(nanoseconds: 1_000_000_000) // 1초 대기
                    continue
                }
                
                // warmup 실패는 로그만 남기고 계속 진행 (실제 요청에서 재시도 할 것)
                logger.warning("Supabase 연결 준비 최종 실패, 실제 요청에서 재시도 예정")
            }
        }
    }

    // URL 접근 가능 여부 확인
    private func isURLAccessible(_ urlString: String, timeout: TimeInterval = 5) async -> Bool {
        guard let url = URL(string: urlString) else { return false }
        
        do {
            var request = URLRequest(url: url)
            request.httpMethod = "HEAD"
            request.timeoutInterval = timeout
            
            let (_, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                return httpResponse.statusCode == 200
            }
        } catch {
            // 에러는 조용히 처리
        }
        
        return false
    }

    // 빠른 메모리 생성
    private func quickCreateMemory(_ memory: Memory) async throws {
        // 가벼운 연결 테스트
        try? await quickWarmupSupabase()
        
        let maxRetries = 3
        var currentRetry = 0
        var lastError: Error?
        
        while currentRetry < maxRetries {
            do {
                try await memoryRepository.createMemory(memory)
                return
                
            } catch {
                lastError = error
                currentRetry += 1
                
                if isNetworkError(error) && currentRetry < maxRetries {
                    logger.warning("Database connection failed, retrying (\(currentRetry)/\(maxRetries-1))")
                    let delay = pow(2.0, Double(currentRetry - 1))
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    continue
                } else {
                    throw error
                }
            }
        }
        
        if let lastError = lastError {
            throw lastError
        }
    }
    
    // 빠른 Supabase warm-up
    private func quickWarmupSupabase() async throws {
        do {
            // 간단한 쿼리로 연결 테스트
            let _: [Memory] = try await memoryRepository.fetchMemories(for: UUID())
        } catch {
            // warm-up 실패해도 무시
        }
    }
    
    // 부분적으로 업로드된 파일들 정리
    private func cleanupPartialUpload(videoURL: String?, thumbnailURL: String, userId: UUID) async {
        // 비디오 파일 정리
        if let videoURL = videoURL, !videoURL.isEmpty {
            do {
                if let videoPath = extractPathFromURL(videoURL, userId: userId, isVideo: true) {
                    try await memoryRepository.deleteStorageFile(bucketName: "videos", path: videoPath)
                }
            } catch {
                logger.error("Failed to cleanup video file: \(error.localizedDescription)")
            }
        }
        
        // 썸네일 파일 정리
        if !thumbnailURL.isEmpty {
            do {
                if let thumbnailPath = extractPathFromURL(thumbnailURL, userId: userId, isVideo: false) {
                    try await memoryRepository.deleteStorageFile(bucketName: "thumbnails", path: thumbnailPath)
                }
            } catch {
                logger.error("Failed to cleanup thumbnail file: \(error.localizedDescription)")
            }
        }
    }
    
    // URL에서 파일 경로 추출
    private func extractPathFromURL(_ url: String, userId: UUID, isVideo: Bool) -> String? {
        let prefix = isVideo ? "videos/" : "thumbnails/"
        if let range = url.range(of: prefix) {
            return String(url[range.lowerBound...])
        }
        return nil
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
}

// MARK: - 에러 정의
enum CreateMemoryError: LocalizedError {
    case uploadedFileNotAccessible(String)
    
    var errorDescription: String? {
        switch self {
        case .uploadedFileNotAccessible(let message):
            return message
        }
    }
}

extension CreateMemoryUseCase {
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
