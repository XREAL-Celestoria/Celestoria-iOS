//
//  CachedAsyncImage.swift
//  Celestoria
//
//  Created by Assistant on 8/3/25.
//

import SwiftUI
import os

// MARK: - Cached Async Image
struct CachedAsyncImage: View {
    let urlString: String
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
        guard !urlString.isEmpty else {
            isLoading = false
            hasError = true
            return
        }
        
        isLoading = true
        hasError = false
        
        Logger.info("CachedAsyncImage: Starting to load image - \(urlString)")
        
        Task {
            if let loadedImage = await ImageCache.shared.loadImage(from: urlString) {
                await MainActor.run {
                    self.image = loadedImage
                    self.isLoading = false
                    Logger.info("CachedAsyncImage: Successfully loaded image - \(urlString)")
                }
            } else {
                await MainActor.run {
                    self.isLoading = false
                    self.hasError = true
                    Logger.error("CachedAsyncImage: Failed to load image - \(urlString)")
                }
            }
        }
    }
} 