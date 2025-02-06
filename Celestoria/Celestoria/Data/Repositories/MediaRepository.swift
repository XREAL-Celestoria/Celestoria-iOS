//
//  MediaRepository.swift
//  Celestoria
//
//  Created by Park Seyoung on 1/23/25.
//  (Backblaze B2 + Cloudflare 연동 버전)
//

import Foundation
import UIKit
import AVFoundation
import CryptoKit
import os

// MARK: - Backblaze B2 및 Cloudflare 설정 (credential 하드코딩)
// Backblaze credential
private let b2KeyID = "004fc386bb8c7730000000001"                   // Backblaze B2 Application Key ID
private let b2ApplicationKey = "K00464cSENYJo6rBn1x1gqwdp1kRiyM"       // Backblaze B2 Application Key
private let b2BucketId = "7f9cd368861bdbb89c470713"                   // celestoria 버킷의 Bucket ID (Backblaze 웹 콘솔에서 확인)
private let bucketName = "celestoria"                                  // 버킷 이름 (public)
// Cloudflare 연동: Cloudflare에 이미 개인 도메인(e.g., https://files.applevisionpro.xyz)을 연동해두었음
private let cloudflareDomain = "https://files.applevisionpro.xyz"      // Cloudflare 프록시 도메인

class MediaRepository {
    
    // MARK: - Public API (기존 인터페이스 그대로)
    
    // 동영상 업로드
    func uploadVideo(data: Data, userId: UUID) async throws -> (url: String, metadata: Memory.SpatialMetadata?) {
        os.Logger.info("uploadVideo 시작 - data size: \(data.count) bytes")
        let (validatedData, metadata) = try await validateAndExtractMetadata(from: data)
        let uploadResult = try await uploadToB2(data: validatedData,
                                                folder: "spatial_videos",
                                                fileExtension: "mov",
                                                userId: userId,
                                                mimeType: "video/quicktime")
        os.Logger.info("uploadVideo 완료 - public URL: \(uploadResult.url)")
        return (url: uploadResult.url, metadata: metadata)
    }
    
    // 썸네일 업로드
    func uploadThumbnail(image: UIImage, userId: UUID) async throws -> String {
        os.Logger.info("uploadThumbnail 시작")
        guard let imageData = image.pngData() else {
            os.Logger.info("uploadThumbnail 실패: 이미지 PNG 변환 실패")
            throw MediaError.invalidFormat
        }
        let uploadResult = try await uploadToB2(data: imageData,
                                                folder: "thumbnails",
                                                fileExtension: "png",
                                                userId: userId,
                                                mimeType: "image/png")
        os.Logger.info("uploadThumbnail 완료 - public URL: \(uploadResult.url)")
        return uploadResult.url
    }
    
    // 프로필 이미지 업로드
    func uploadProfileImage(_ image: UIImage, userId: UUID) async throws -> (url: String, path: String) {
        os.Logger.info("uploadProfileImage 시작")
        guard let imageData = image.pngData() else {
            os.Logger.info("uploadProfileImage 실패: 프로필 이미지 PNG 변환 실패")
            throw MemoryError.invalidImageData
        }
        let fileName = "\(UUID().uuidString).png"
        let path = "\(userId.uuidString)/\(fileName)"
        let uploadResult = try await uploadToB2(data: imageData,
                                                folder: "profiles",
                                                fileExtension: "png",
                                                userId: userId,
                                                mimeType: "image/png",
                                                customFileName: fileName)
        os.Logger.info("uploadProfileImage 완료 - public URL: \(uploadResult.url)")
        return (url: uploadResult.url, path: path)
    }
    
    // MARK: - Private Helpers
    
    /// 동영상 검증 및 메타데이터 추출 (기존 로직 그대로)
    private func validateAndExtractMetadata(from data: Data) async throws -> (Data, Memory.SpatialMetadata?) {
        os.Logger.info("validateAndExtractMetadata 시작")
        let tempFileURL = try await createTempFile(with: data)
        os.Logger.info("임시 파일 생성됨: \(tempFileURL.path)")
        defer {
            try? FileManager.default.removeItem(at: tempFileURL)
            os.Logger.info("임시 파일 삭제됨: \(tempFileURL.path)")
        }
        
        let asset = AVURLAsset(url: tempFileURL)
        guard try await validateMVHEVC(asset: asset) else {
            os.Logger.info("MV-HEVC 포맷 검증 실패")
            throw MediaError.invalidFormat
        }
        let metadata = try await extractSpatialMetadata(from: asset)
        os.Logger.info("메타데이터 추출 완료")
        return (data, metadata)
    }
    
    /// 파일 업로드: Backblaze B2에 업로드한 후 Cloudflare 도메인으로 구성된 public URL 반환
    private func uploadToB2(data: Data, folder: String, fileExtension: String, userId: UUID, mimeType: String, customFileName: String? = nil) async throws -> (url: String, path: String) {
        os.Logger.info("uploadToB2 시작 - folder: \(folder), mimeType: \(mimeType)")
        let fileName = customFileName ?? "\(UUID().uuidString).\(fileExtension)"
        let path = "\(folder)/\(userId.uuidString)/\(fileName)"  // folder를 최상위 경로로 이동
        
        // 1. Backblaze B2 인증 (b2_authorize_account)
        let (accountAuthToken, apiUrl, _) = try await b2Authorize()
        os.Logger.info("b2_authorize_account 완료 - apiUrl: \(apiUrl)")
        
        // 2. 업로드 URL 요청 (b2_get_upload_url)
        let (uploadUrl, uploadAuthToken) = try await b2GetUploadURL(bucketId: b2BucketId, accountAuthToken: accountAuthToken, apiUrl: apiUrl)
        os.Logger.info("b2_get_upload_url 완료 - uploadUrl: \(uploadUrl)")
        
        // 3. 파일 업로드 (b2_upload_file)
        try await b2UploadFile(uploadUrl: uploadUrl, uploadAuthToken: uploadAuthToken, fileName: path, data: data, mimeType: mimeType)
        os.Logger.info("b2_upload_file 완료 - 파일 경로: \(path)")
        
        // 4. Cloudflare 연동: DB에 저장할 public URL은 Cloudflare 도메인과 파일 경로만 포함함.
        // Transform Rule이 들어오는 요청에 "/file/celestoria"를 자동으로 추가하여 오리진 URL을 구성할 예정임.
        let publicURL = "\(cloudflareDomain)/\(bucketName)/\(path)"
        os.Logger.info("publicURL 구성 완료 - URL: \(publicURL)")
        return (url: publicURL, path: path)
    }
    
    /// 임시 파일 생성 (기존 로직 그대로)
    private func createTempFile(with data: Data) async throws -> URL {
        let tempDirectory = FileManager.default.temporaryDirectory
        let tempFileURL = tempDirectory.appendingPathComponent("\(UUID().uuidString).mov")
        try data.write(to: tempFileURL)
        return tempFileURL
    }
    
    /// MV-HEVC 포맷 검증 (기존 로직 그대로)
    private func validateMVHEVC(asset: AVURLAsset) async throws -> Bool {
        os.Logger.info("validateMVHEVC 호출")
        guard let track = try await asset.loadTracks(withMediaType: .video).first,
              let formatDescription = try await track.load(.formatDescriptions).first else {
            os.Logger.info("트랙 또는 포맷 디스크립션 로드 실패")
            return false
        }
        let codecType = CMFormatDescriptionGetMediaSubType(formatDescription)
        let isHEVC = codecType == kCMVideoCodecType_HEVC
        os.Logger.info("codecType: \(codecType), isHEVC: \(isHEVC)")
        return isHEVC
    }
    
    /// 메타데이터 추출 (기존 로직 그대로)
    private func extractSpatialMetadata(from asset: AVAsset) async throws -> Memory.SpatialMetadata? {
        os.Logger.info("extractSpatialMetadata 호출")
        guard let videoTrack = try await asset.loadTracks(withMediaType: .video).first else {
            os.Logger.info("videoTrack 로드 실패")
            return nil
        }
        let formatDescriptions = try await videoTrack.load(.formatDescriptions)
        guard let formatDescription = formatDescriptions.first,
              let extensions = CMFormatDescriptionGetExtensions(formatDescription) as? [String: Any] else {
            os.Logger.info("포맷 디스크립션 또는 확장 정보 로드 실패")
            return nil
        }
        os.Logger.info("확장 정보: \(extensions)")
        return Memory.SpatialMetadata(
            projectionKind: extensions["ProjectionKind"] as? String ?? "",
            hasLeftStereoEyeView: extensions["HasLeftStereoEyeView"] as? Int == 1,
            hasRightStereoEyeView: extensions["HasRightStereoEyeView"] as? Int == 1,
            stereoCameraBaseline: extensions["StereoCameraBaseline"] as? Int ?? 0,
            spatialQuality: extensions["SpatialQuality"] as? Int ?? 0,
            horizontalFieldOfView: extensions["HorizontalFieldOfView"] as? Int ?? 0
        )
    }
    
    // MARK: - Backblaze B2 API 호출
    
    /// b2_authorize_account 호출
    /// - Returns: (accountAuthToken, apiUrl, downloadUrl)
    private func b2Authorize() async throws -> (String, String, String) {
        os.Logger.info("b2_authorize_account 호출")
        guard let url = URL(string: "https://api.backblazeb2.com/b2api/v2/b2_authorize_account") else {
            throw MediaError.uploadFailed()
        }
        let authString = "\(b2KeyID):\(b2ApplicationKey)"
        guard let authData = authString.data(using: .utf8) else {
            throw MediaError.uploadFailed()
        }
        let base64Auth = authData.base64EncodedString()
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Basic \(base64Auth)", forHTTPHeaderField: "Authorization")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        os.Logger.info("b2_authorize_account 응답 데이터 크기: \(data.count) bytes")
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let authToken = json["authorizationToken"] as? String,
              let apiUrl = json["apiUrl"] as? String,
              let downloadUrl = json["downloadUrl"] as? String else {
            os.Logger.info("b2_authorize_account JSON 파싱 실패")
            throw MediaError.uploadFailed()
        }
        os.Logger.info("b2_authorize_account 성공 - authToken: \(authToken.prefix(6))..., apiUrl: \(apiUrl)")
        return (authToken, apiUrl, downloadUrl)
    }
    
    /// b2_get_upload_url 호출
    /// - Returns: (uploadUrl, uploadAuthToken)
    private func b2GetUploadURL(bucketId: String, accountAuthToken: String, apiUrl: String) async throws -> (String, String) {
        os.Logger.info("b2_get_upload_url 호출")
        guard let url = URL(string: "\(apiUrl)/b2api/v2/b2_get_upload_url") else {
            throw MediaError.uploadFailed()
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        // Bearer 접두사 제거하고 토큰 직접 사용
        request.setValue(accountAuthToken, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        os.Logger.info("Authorization 헤더: \(String(accountAuthToken.prefix(10)))...")
        
        let body = ["bucketId": bucketId]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let responseString = String(data: data, encoding: .utf8) {
            os.Logger.info("b2_get_upload_url 응답: \(responseString)")
        }
        
        if let httpResponse = response as? HTTPURLResponse {
            os.Logger.info("b2_get_upload_url HTTP 상태 코드: \(httpResponse.statusCode)")
            if httpResponse.statusCode == 401 {
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let code = json["code"] as? String,
                   let message = json["message"] as? String {
                    throw MediaError.uploadFailed(message: "인증 실패 - \(code): \(message)")
                }
            }
            guard (200...299).contains(httpResponse.statusCode) else {
                throw MediaError.uploadFailed(message: "HTTP 에러: \(httpResponse.statusCode)")
            }
        }
        
        do {
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let uploadUrl = json["uploadUrl"] as? String,
                  let uploadAuthToken = json["authorizationToken"] as? String else {
                os.Logger.info("b2_get_upload_url JSON 파싱 실패 - 필수 필드 누락")
                throw MediaError.uploadFailed(message: "JSON 파싱 실패")
            }
            os.Logger.info("b2_get_upload_url 성공 - uploadUrl: \(uploadUrl)")
            return (uploadUrl, uploadAuthToken)
        } catch {
            os.Logger.info("b2_get_upload_url JSON 파싱 에러: \(error.localizedDescription)")
            throw MediaError.uploadFailed(message: "JSON 파싱 에러: \(error.localizedDescription)")
        }
    }
    
    /// b2_upload_file 호출 - 업로드용 URL과 토큰을 사용하여 파일 업로드
    private func b2UploadFile(uploadUrl: String, uploadAuthToken: String, fileName: String, data: Data, mimeType: String) async throws {
        let maxRetries = 3
        var currentRetry = 0
        
        while currentRetry < maxRetries {
            do {
                guard let url = URL(string: uploadUrl) else {
                    throw MediaError.uploadFailed()
                }
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue(uploadAuthToken, forHTTPHeaderField: "Authorization")
                let encodedFileName = fileName.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? fileName
                request.setValue(encodedFileName, forHTTPHeaderField: "X-Bz-File-Name")
                request.setValue(mimeType, forHTTPHeaderField: "Content-Type")
                request.setValue(String(data.count), forHTTPHeaderField: "Content-Length")
                request.timeoutInterval = 3600
                
                let sha1Hash: String = {
                    #if DEBUG
                    return "do_not_verify"
                    #else
                    let digest = Insecure.SHA1.hash(data: data)
                    return digest.map { String(format: "%02x", $0) }.joined()
                    #endif
                }()
                request.setValue(sha1Hash, forHTTPHeaderField: "X-Bz-Content-Sha1")
                request.httpBody = data
                
                let configuration = URLSessionConfiguration.default
                configuration.timeoutIntervalForResource = 3600
                configuration.timeoutIntervalForRequest = 3600
                let session = URLSession(configuration: configuration)
                
                let (responseData, response) = try await session.data(for: request)
                
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200 {
                        os.Logger.info("b2_upload_file 성공")
                        return // 성공하면 함수 종료
                    } else {
                        if let errorString = String(data: responseData, encoding: .utf8) {
                            os.Logger.error("b2_upload_file 실패 - HTTP 응답 코드: \(httpResponse.statusCode), 에러: \(errorString)")
                        }
                        
                        // 500 에러인 경우 재시도
                        if httpResponse.statusCode == 500 {
                            currentRetry += 1
                            if currentRetry < maxRetries {
                                os.Logger.info("b2_upload_file 재시도 중... (시도 \(currentRetry)/\(maxRetries))")
                                try await Task.sleep(nanoseconds: UInt64(pow(2.0, Double(currentRetry)) * 1_000_000_000)) // 지수 백오프
                                continue
                            }
                        }
                        
                        throw MediaError.uploadFailed(message: "업로드 실패 (HTTP \(httpResponse.statusCode))")
                    }
                } else {
                    throw MediaError.uploadFailed()
                }
            } catch {
                currentRetry += 1
                if currentRetry >= maxRetries {
                    throw error
                }
                os.Logger.info("b2_upload_file 재시도 중... (시도 \(currentRetry)/\(maxRetries))")
                try await Task.sleep(nanoseconds: UInt64(pow(2.0, Double(currentRetry)) * 1_000_000_000))
            }
        }
        
        throw MediaError.uploadFailed(message: "최대 재시도 횟수 초과")
    }
}

enum MediaError: LocalizedError {
    case invalidFormat
    case metadataExtractionFailed
    case uploadFailed(message: String? = nil)
    
    var errorDescription: String? {
        switch self {
        case .invalidFormat:
            return "비디오 포맷이 올바르지 않습니다. Spatial Video 형식인지 확인해주세요."
        case .metadataExtractionFailed:
            return "메타데이터 추출에 실패했습니다."
        case .uploadFailed(let message):
            return message ?? "비디오 업로드에 실패했습니다."
        }
    }
}
