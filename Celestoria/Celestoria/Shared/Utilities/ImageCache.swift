//
//  ImageCache.swift
//  Celestoria
//
//  Created by Assistant on 8/3/25.
//

import Foundation
import UIKit
import os

// MARK: - Image Cache Manager
class ImageCache {
    static let shared = ImageCache()
    private let cache = NSCache<NSString, UIImage>()
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    
    private init() {
        // 캐시 디렉토리 설정
        let paths = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        cacheDirectory = paths[0].appendingPathComponent("ImageCache")
        
        // 캐시 디렉토리 생성
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        
        // 메모리 캐시 설정
        cache.countLimit = 100 // 최대 100개 이미지
        cache.totalCostLimit = 50 * 1024 * 1024 // 50MB
        
        Logger.info("ImageCache initialized with directory: \(cacheDirectory.path)")
    }
    
    // MARK: - Public Methods
    
    /// 이미지 로딩 (캐시에서 먼저 확인)
    func loadImage(from urlString: String, timeout: TimeInterval = 10) async -> UIImage? {
        Logger.info("ImageCache: loadImage called for - \(urlString)")
        let key = NSString(string: urlString)
        
        // 1. 메모리 캐시 확인
        if let cachedImage = cache.object(forKey: key) {
            Logger.info("ImageCache: Found in memory cache - \(urlString)")
            return cachedImage
        }
        
        Logger.info("ImageCache: Not found in memory cache, checking disk - \(urlString)")
        
        // 2. 디스크 캐시 확인
        if let diskCachedImage = loadFromDisk(key: key) {
            Logger.info("ImageCache: Found in disk cache - \(urlString)")
            cache.setObject(diskCachedImage, forKey: key)
            return diskCachedImage
        }
        
        Logger.info("ImageCache: Not found in disk cache, loading from network - \(urlString)")
        
        // 3. 네트워크에서 로딩
        guard let url = URL(string: urlString) else {
            Logger.error("ImageCache: Invalid URL - \(urlString)")
            return nil
        }
        
        do {
            let configuration = URLSessionConfiguration.default
            configuration.timeoutIntervalForRequest = timeout
            configuration.timeoutIntervalForResource = timeout * 2
            configuration.waitsForConnectivity = false // 연결 대기 비활성화
            configuration.requestCachePolicy = .returnCacheDataElseLoad // 캐시 우선 사용
            let session = URLSession(configuration: configuration)
            
            Logger.info("ImageCache: Starting network request - \(urlString)")
            let (data, response) = try await session.data(from: url)
            
            // HTTP 응답 상태 확인
            if let httpResponse = response as? HTTPURLResponse {
                Logger.info("ImageCache: HTTP Status: \(httpResponse.statusCode), Content-Type: \(httpResponse.value(forHTTPHeaderField: "Content-Type") ?? "unknown"), data size: \(data.count) bytes - \(urlString)")
                
                // HTTP 에러 상태 확인
                guard httpResponse.statusCode == 200 else {
                    Logger.error("ImageCache: HTTP Error \(httpResponse.statusCode) - \(urlString)")
                    // 에러 응답 데이터 내용 로깅 (최대 200자)
                    if let errorString = String(data: data, encoding: .utf8) {
                        let truncated = String(errorString.prefix(200))
                        Logger.error("ImageCache: Error response: \(truncated)")
                    }
                    return nil
                }
                
                // Content-Type 확인 (선택사항, 일부 서버는 올바른 Content-Type을 반환하지 않을 수 있음)
                let contentType = httpResponse.value(forHTTPHeaderField: "Content-Type")?.lowercased()
                if let contentType = contentType, !contentType.contains("image") {
                    Logger.warning("ImageCache: Unexpected Content-Type: \(contentType) - \(urlString)")
                }
            }
            
            Logger.info("ImageCache: Network request completed, data size: \(data.count) bytes - \(urlString)")
            
            guard let image = UIImage(data: data) else {
                Logger.error("ImageCache: Failed to create image from data - \(urlString)")
                // 데이터 시작 부분 로깅 (디버깅용)
                let dataPrefix = data.prefix(50)
                let hexString = dataPrefix.map { String(format: "%02x", $0) }.joined(separator: " ")
                Logger.error("ImageCache: Data hex prefix: \(hexString)")
                return nil
            }
            
            // 메모리와 디스크에 캐시
            cache.setObject(image, forKey: key)
            saveToDisk(image: image, key: key)
            
            Logger.info("ImageCache: Successfully loaded and cached - \(urlString)")
            return image
            
        } catch {
            Logger.error("ImageCache: Failed to load image - \(urlString), error: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// 프로필 이미지 미리 로딩
    func preloadProfileImage(urlString: String) async {
        // 이미 캐시되어 있으면 스킵
        let key = NSString(string: urlString)
        if cache.object(forKey: key) != nil || loadFromDisk(key: key) != nil {
            Logger.info("ImageCache: Profile image already cached, skipping preload - \(urlString)")
            return
        }
        
        Logger.info("ImageCache: Preloading profile image - \(urlString)")
        _ = await loadImage(from: urlString)
    }
    
    /// 여러 프로필 이미지 미리 로딩
    func preloadProfileImages(urlStrings: [String]) async {
        await withTaskGroup(of: Void.self) { group in
            for urlString in urlStrings {
                group.addTask {
                    await self.preloadProfileImage(urlString: urlString)
                }
            }
        }
    }
    
    /// 캐시 정리
    func clearCache() {
        cache.removeAllObjects()
        try? fileManager.removeItem(at: cacheDirectory)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        Logger.info("ImageCache: Cache cleared")
    }
    
    // MARK: - Private Methods
    
    private func saveToDisk(image: UIImage, key: NSString) {
        guard let data = image.jpegData(compressionQuality: 0.8) else { 
            Logger.error("ImageCache: Failed to convert image to JPEG data")
            return 
        }
        
        let fileURL = cacheDirectory.appendingPathComponent(key.hash.description)
        do {
            try data.write(to: fileURL)
            Logger.info("ImageCache: Successfully saved to disk - \(fileURL.lastPathComponent)")
        } catch {
            Logger.error("ImageCache: Failed to save to disk - \(error.localizedDescription)")
        }
    }
    
    private func loadFromDisk(key: NSString) -> UIImage? {
        let fileURL = cacheDirectory.appendingPathComponent(key.hash.description)
        guard let data = try? Data(contentsOf: fileURL) else { 
            Logger.info("ImageCache: No cached file found on disk - \(fileURL.lastPathComponent)")
            return nil 
        }
        
        guard let image = UIImage(data: data) else {
            Logger.error("ImageCache: Failed to create image from disk data - \(fileURL.lastPathComponent)")
            return nil
        }
        
        Logger.info("ImageCache: Successfully loaded from disk - \(fileURL.lastPathComponent)")
        return image
    }
} 