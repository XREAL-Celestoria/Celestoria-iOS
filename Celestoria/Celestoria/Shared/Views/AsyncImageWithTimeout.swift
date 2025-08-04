//
//  AsyncImageWithTimeout.swift
//  Celestoria
//
//  Created by Assistant on 8/3/25.
//

import SwiftUI
import os

// MARK: - Custom AsyncImage with Timeout for iOS
struct AsyncImageWithTimeout: View {
    let url: URL
    let size: CGFloat
    @State private var image: UIImage?
    @State private var isLoading = true
    @State private var hasError = false
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else if isLoading {
                ProgressView()
                    .frame(width: size * 0.5, height: size * 0.5)
                    .foregroundColor(.gray)
            } else {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: size))
                    .foregroundColor(.gray)
            }
        }
        .onAppear {
            loadImage()
        }
    }
    
    private func loadImage() {
        isLoading = true
        hasError = false
        
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 10 // 10초 타임아웃
        configuration.timeoutIntervalForResource = 30 // 전체 리소스 타임아웃 30초
        let session = URLSession(configuration: configuration)
        
        Task {
            do {
                let (data, response) = try await session.data(from: url)
                
                // HTTP 응답 상태 확인
                if let httpResponse = response as? HTTPURLResponse {
                    Logger.info("AsyncImageWithTimeout: HTTP Status: \(httpResponse.statusCode), Content-Type: \(httpResponse.value(forHTTPHeaderField: "Content-Type") ?? "unknown"), data size: \(data.count) bytes")
                    
                    // HTTP 에러 상태 확인
                    guard httpResponse.statusCode == 200 else {
                        Logger.error("AsyncImageWithTimeout: HTTP Error \(httpResponse.statusCode)")
                        // 에러 응답 데이터 내용 로깅 (최대 200자)
                        if let errorString = String(data: data, encoding: .utf8) {
                            let truncated = String(errorString.prefix(200))
                            Logger.error("AsyncImageWithTimeout: Error response: \(truncated)")
                        }
                        throw URLError(.badServerResponse)
                    }
                }
                
                if let uiImage = UIImage(data: data) {
                    await MainActor.run {
                        self.image = uiImage
                        self.isLoading = false
                        Logger.info("AsyncImageWithTimeout: Image loaded successfully")
                    }
                } else {
                    // 데이터 시작 부분 로깅 (디버깅용)
                    let dataPrefix = data.prefix(50)
                    let hexString = dataPrefix.map { String(format: "%02x", $0) }.joined(separator: " ")
                    Logger.error("AsyncImageWithTimeout: Failed to create image from data, hex prefix: \(hexString)")
                    throw URLError(.cannotDecodeContentData)
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.hasError = true
                    Logger.error("AsyncImageWithTimeout: Failed to load image - \(error.localizedDescription)")
                }
            }
        }
    }
} 