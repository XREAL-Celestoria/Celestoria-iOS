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
                let (data, _) = try await session.data(from: url)
                if let uiImage = UIImage(data: data) {
                    await MainActor.run {
                        self.image = uiImage
                        self.isLoading = false
                        Logger.info("AsyncImageWithTimeout: Image loaded successfully")
                    }
                } else {
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