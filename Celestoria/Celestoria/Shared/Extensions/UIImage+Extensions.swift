//
//  UIImage+Extensions.swift
//  Celestoria
//
//  Created by AI Assistant on 8/4/25.
//

import UIKit

extension UIImage {
    
    /// 이미지를 지정된 최대 크기로 리사이징합니다
    /// - Parameter maxSize: 최대 크기 (너비 또는 높이 중 더 큰 값)
    /// - Returns: 리사이징된 UIImage
    func resized(to maxSize: CGFloat) -> UIImage {
        let originalSize = self.size
        
        // 이미 작은 이미지라면 그대로 반환
        if max(originalSize.width, originalSize.height) <= maxSize {
            return self
        }
        
        // 비율을 유지하면서 리사이징
        let ratio = min(maxSize / originalSize.width, maxSize / originalSize.height)
        let newSize = CGSize(width: originalSize.width * ratio, height: originalSize.height * ratio)
        
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
    
    /// 프로필 이미지에 최적화된 리사이징 (정사각형으로 크롭 후 리사이징)
    /// - Parameter size: 원하는 크기 (기본값: 400x400)
    /// - Returns: 정사각형으로 크롭되고 리사이징된 UIImage
    func optimizedForProfile(size: CGFloat = 400) -> UIImage {
        let originalSize = self.size
        
        // 정사각형 크롭을 위한 최소 사이즈 계산
        let minDimension = min(originalSize.width, originalSize.height)
        let cropSize = CGSize(width: minDimension, height: minDimension)
        
        // 중앙에서 크롭할 영역 계산
        let cropRect = CGRect(
            x: (originalSize.width - minDimension) / 2,
            y: (originalSize.height - minDimension) / 2,
            width: minDimension,
            height: minDimension
        )
        
        // 크롭된 이미지 생성
        let croppedImage: UIImage
        if let cgImage = self.cgImage?.cropping(to: cropRect) {
            croppedImage = UIImage(cgImage: cgImage, scale: self.scale, orientation: self.imageOrientation)
        } else {
            croppedImage = self
        }
        
        // 지정된 크기로 리사이징
        if minDimension <= size {
            return croppedImage
        }
        
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        return renderer.image { _ in
            croppedImage.draw(in: CGRect(origin: .zero, size: CGSize(width: size, height: size)))
        }
    }
    
    /// 고품질 JPEG 데이터 생성 (프로필 이미지용)
    /// - Parameter compressionQuality: 압축 품질 (기본값: 0.7)
    /// - Returns: 압축된 JPEG 데이터
    func optimizedJPEGData(compressionQuality: CGFloat = 0.7) -> Data? {
        return self.jpegData(compressionQuality: compressionQuality)
    }
}