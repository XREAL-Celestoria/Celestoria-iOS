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
import os

class MediaRepository {
    private let supabase: SupabaseClient
    
    init(supabase: SupabaseClient) {
        self.supabase = supabase
    }
    
    // UploadingVideo
    func uploadVideo(data: Data, userId: UUID) async throws -> (url: String, metadata: Memory.SpatialMetadata?) {
        os.Logger.info("Uploading video... Size: \(data.count) bytes")
        
        do {
            os.Logger.info("Validating video format and extracting metadata...")
            let (validatedData, metadata) = try await validateAndExtractMetadata(from: data)
            os.Logger.info("Validation and metadata extraction completed.")
            
            os.Logger.info("Starting upload to Supabase...")
            let uploadResult = try await uploadToSupabase(validatedData, folder: "spatial_videos", fileExtension: "mov", userId: userId)
            os.Logger.info("Video uploaded successfully. URL: \(uploadResult.url)")
            return (url: uploadResult.url, metadata: metadata)
        } catch let error as MediaError {
            os.Logger.error("MediaError during video upload: \(error.localizedDescription)")
            throw error
        } catch {
            os.Logger.error("Unexpected error during video upload: \(error.localizedDescription)")
            throw error
        }
    }

    // 썸네일 업로드
    func uploadThumbnail(image: UIImage, userId: UUID) async throws -> String {
        os.Logger.info("Uploading thumbnail...")
        guard let imageData = image.pngData() else
        {
            let error = MediaError.invalidFormat
            os.Logger.error("Failed to convert image to PNG: \(error.localizedDescription)")
            throw error
        }
        
        do {
            let uploadResult = try await uploadToSupabase(imageData, folder: "thumbnails", fileExtension: "png", userId: userId)
            os.Logger.info("Thumbnail uploaded successfully. URL: \(uploadResult.url)")
            return uploadResult.url
        } catch {
            os.Logger.error("Thumbnail upload failed: \(error.localizedDescription)")
            throw error
        }
    }

    // 프로필 이미지 업로드를 위한 public 메서드
    func uploadProfileImage(_ image: UIImage, userId: UUID) async throws -> (url: String, path: String) {
        os.Logger.info("Starting profile image upload")
        guard let imageData = image.pngData() else {
            os.Logger.error("Failed to convert image to PNG data")
            throw MemoryError.invalidImageData
        }
        
        do {
            let fileName = "\(UUID().uuidString).png"
            let path = "\(userId.uuidString)/\(fileName)"
            
            // storage에 업로드
            try await supabase.storage
                .from("profiles")
                .upload(
                    path,
                    data: imageData,
                    options: .init(
                        contentType: "image/png",
                        upsert: true
                    )
                )
            
            // public URL 생성
            let publicURL = try await supabase.storage
                .from("profiles")
                .createSignedURL(
                    path: path,
                    expiresIn: 365 * 24 * 60 * 60 // 1년
                )
            
            Logger.info("Profile image uploaded successfully - URL: \(publicURL)")
            return (url: publicURL.absoluteString, path: path)
        } catch {
            Logger.error("Error uploading profile image: \(error.localizedDescription)")
            throw error
        }
    }
    
    // 비디오 검증 및 메타데이터 추출
    private func validateAndExtractMetadata(from data: Data) async throws -> (Data, Memory.SpatialMetadata?) {
            do {
                os.Logger.info("Validating video format...")
                let tempFileURL = try await createTempFile(with: data)
                defer { try? FileManager.default.removeItem(at: tempFileURL) }
                
                let asset = AVURLAsset(url: tempFileURL)
                guard try await validateMVHEVC(asset: asset) else {
                    let error = MediaError.invalidFormat
                    os.Logger.error("Video validation failed: \(error.localizedDescription)")
                    throw error
                }
                
                os.Logger.info("Extracting metadata...")
                let metadata = try await extractSpatialMetadata(from: asset)
                os.Logger.info("Metadata extracted successfully")
                return (data, metadata)
            } catch {
                os.Logger.error("Validation or metadata extraction failed: \(error.localizedDescription)")
                throw error
            }
        }
    
    // Supabase에 업로드
    private func uploadToSupabase(_ data: Data, folder: String, fileExtension: String, userId: UUID) async throws -> (url: String, path: String) {
        let fileName = "\(UUID().uuidString).\(fileExtension)"
        let path = "\(userId.uuidString)/\(fileName)"
        
        os.Logger.info("Uploading file: \(fileName), Size: \(data.count) bytes")
        
        do {
            try await supabase.storage.from(folder).upload(path, data: data, options: .init(upsert: true))
            let publicURL = try await supabase.storage.from(folder).createSignedURL(path: path, expiresIn: 604800)
            os.Logger.info("File uploaded successfully. Public URL: \(publicURL)")
            return (url: publicURL.absoluteString, path: path)
        } catch {
            if let nsError = error as NSError? {
                os.Logger.error("Supabase upload failed. Error Code: \(nsError.code), Domain: \(nsError.domain), Description: \(nsError.localizedDescription)")
            } else {
                os.Logger.error("Supabase upload failed with unknown error: \(error.localizedDescription)")
            }
            throw MediaError.uploadFailed
        }
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
