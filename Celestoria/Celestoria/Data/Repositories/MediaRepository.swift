//
//  MediaRepository.swift
//  Celestoria
//
//  Created by Park Seyoung on 1/23/25.
//


import Foundation
import Supabase
import UIKit
import AVFoundation

class MediaRepository {
    private let supabase: SupabaseClient
    
    init(supabase: SupabaseClient) {
        self.supabase = supabase
    }
    
    // UploadingVideo
    func uploadVideo(data: Data) async throws -> (url: String, metadata: Memory.SpatialMetadata?) {
        let (validatedData, metadata) = try await validateAndExtractMetadata(from: data)
        let uploadResult = try await uploadToSupabase(validatedData, folder: "spatial_videos")
        
        return (url: uploadResult.url, metadata: metadata)
    }
    
    // 썸네일 업로드
    func uploadThumbnail(image: UIImage) async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw MemoryError.invalidImageData
        }
        return try await uploadToSupabase(imageData, folder: "thumbnails").url
    }
    
    // 비디오 검증 및 메타데이터 추출
    private func validateAndExtractMetadata(from data: Data) async throws -> (Data, Memory.SpatialMetadata?) {
        let tempFileURL = try await createTempFile(with: data)
        defer { try? FileManager.default.removeItem(at: tempFileURL) }
        
        let asset = AVURLAsset(url: tempFileURL)
        
        guard try await validateMVHEVC(asset: asset) else {
            throw MediaError.invalidFormat
        }
        
        let metadata = try await extractSpatialMetadata(from: asset)
        return (data, metadata)
    }
    
    // Supabase에 업로드
    private func uploadToSupabase(_ data: Data, folder: String) async throws -> (url: String, path: String) {
        let fileName = "\(UUID().uuidString)"
        let path = "\(fileName)"
        
        try await supabase.storage.from(folder).upload(path, data: data, options: .init(upsert: true))
        
        let publicURL = try await supabase.storage.from(folder).createSignedURL(path: path, expiresIn: 604800)
        return (url: publicURL.absoluteString, path: path)
    }
    
    // 임시 파일 생성
    private func createTempFile(with data: Data) async throws -> URL {
        let tempDirectory = FileManager.default.temporaryDirectory
        let tempFileURL = tempDirectory.appendingPathComponent("\(UUID().uuidString).mov")
        try data.write(to: tempFileURL)
        return tempFileURL
    }
    
    // MV-HEVC 포맷 검증
    private func validateMVHEVC(asset: AVURLAsset) async throws -> Bool {
        guard let track = try await asset.loadTracks(withMediaType: .video).first,
              let formatDescription = try await track.load(.formatDescriptions).first else {
            return false
        }
        let codecType = CMFormatDescriptionGetMediaSubType(formatDescription)
        return codecType == kCMVideoCodecType_HEVC
    }
    
    // 메타데이터 추출
    private func extractSpatialMetadata(from asset: AVAsset) async throws -> Memory.SpatialMetadata? {
        guard let videoTrack = try await asset.loadTracks(withMediaType: .video).first else {
            return nil
        }
        
        let formatDescriptions = try await videoTrack.load(.formatDescriptions)
        guard let formatDescription = formatDescriptions.first,
              let extensions = CMFormatDescriptionGetExtensions(formatDescription) as? [String: Any] else {
            return nil
        }
        
        return Memory.SpatialMetadata(
            projectionKind: extensions["ProjectionKind"] as? String ?? "",
            hasLeftStereoEyeView: extensions["HasLeftStereoEyeView"] as? Int == 1,
            hasRightStereoEyeView: extensions["HasRightStereoEyeView"] as? Int == 1,
            stereoCameraBaseline: extensions["StereoCameraBaseline"] as? Int ?? 0,
            spatialQuality: extensions["SpatialQuality"] as? Int ?? 0,
            horizontalFieldOfView: extensions["HorizontalFieldOfView"] as? Int ?? 0
        )
    }
}

enum MediaError: LocalizedError {
    case invalidFormat
    case metadataExtractionFailed
    case uploadFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidFormat:
            return "비디오 포맷이 올바르지 않습니다. Spatial Video 형식인지 확인해주세요."
        case .metadataExtractionFailed:
            return "메타데이터 추출에 실패했습니다."
        case .uploadFailed:
            return "비디오 업로드에 실패했습니다."
        }
    }
}
