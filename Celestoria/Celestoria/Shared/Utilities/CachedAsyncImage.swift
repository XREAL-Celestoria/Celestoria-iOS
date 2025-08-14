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
    // Optional callbacks to propagate loading/completion state to parent views
    var onLoadingChange: ((Bool) -> Void)? = nil
    var onCompletion: ((Bool) -> Void)? = nil
    
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
            onLoadingChange?(false)
            onCompletion?(false)
            return
        }
        
        isLoading = true
        hasError = false
        onLoadingChange?(true)
        
        Task {
            if let loadedImage = await ImageCache.shared.loadImage(from: urlString) {
                await MainActor.run {
                    self.image = loadedImage
                    self.isLoading = false
                    self.onLoadingChange?(false)
                    self.onCompletion?(true)
                }
            } else {
                await MainActor.run {
                    self.isLoading = false
                    self.hasError = true
                    self.onLoadingChange?(false)
                    self.onCompletion?(false)
                }
            }
        }
    }
}