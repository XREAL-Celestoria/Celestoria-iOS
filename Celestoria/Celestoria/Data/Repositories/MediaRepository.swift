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

// MARK: - 업로드 진행률 타입 정의
/// 업로드 진행률 콜백 (진행률: 0.0~1.0, 상태 메시지)
typealias UploadProgressCallback = (Double, String) -> Void

// MARK: - Backblaze B2 및 Cloudflare 설정 (credential 하드코딩)
// Backblaze credential
private let b2KeyID = Config.b2KeyID
private let b2ApplicationKey = Config.b2ApplicationKey
private let b2BucketId = Config.b2BucketId
private let bucketName = Config.bucketName
private let cloudflareDomain = Config.cloudflareDomain

class MediaRepository {
    
    // MARK: - Public API (기존 인터페이스 그대로)
    
    // 동영상 업로드 (진행률 추적 포함)
    func uploadVideo(data: Data, userId: UUID, progressCallback: UploadProgressCallback? = nil) async throws -> (url: String, metadata: Memory.SpatialMetadata?) {
        os.Logger.info("uploadVideo started - data size: \(data.count) bytes")
        
        // 진행률: 5% - 검증 시작
        progressCallback?(0.05, "Validating Video...")
        let (validatedData, metadata) = try await validateAndExtractMetadata(from: data)
        
        // 진행률: 15% - 업로드 시작
        progressCallback?(0.15, "Starting Upload...")
        let uploadResult = try await uploadToB2(data: validatedData,
                                                folder: "spatial_videos",
                                                fileExtension: "mov",
                                                userId: userId,
                                                mimeType: "video/quicktime",
                                                progressCallback: progressCallback)
        
        // 진행률: 100% - 완료
        progressCallback?(1.0, "Upload Success!")
        os.Logger.info("✅ uploadVideo completed - public URL: \(uploadResult.url)")
        return (url: uploadResult.url, metadata: metadata)
    }
    
    // 썸네일 업로드
    func uploadThumbnail(image: UIImage, userId: UUID) async throws -> String {
        os.Logger.info("uploadThumbnail started")
        
        // 썸네일 최적화: 800px 최대 크기로 리사이징
        let optimizedImage = image.resized(to: 800)
        
        // JPEG 압축 (0.8 품질로 썸네일은 조금 더 높은 품질 유지)
        guard let imageData = optimizedImage.optimizedJPEGData(compressionQuality: 0.8) else {
            os.Logger.info("uploadThumbnail 실패: 이미지 JPEG 변환 실패")
            throw MediaError.invalidFormat
        }
        
        // 최적화된 용량 로깅
        let originalSize = image.pngData()?.count ?? 0
        let optimizedSize = imageData.count
        os.Logger.info("uploadThumbnail 이미지 최적화: \(originalSize) bytes → \(optimizedSize) bytes (압축률: \(String(format: "%.1f", Double(optimizedSize) / Double(originalSize) * 100))%)")
        
        let uploadResult = try await uploadToB2(data: imageData,
                                                folder: "thumbnails",
                                                fileExtension: "jpg",
                                                userId: userId,
                                                mimeType: "image/jpeg")
        os.Logger.info("uploadThumbnail 완료 - public URL: \(uploadResult.url)")
        return uploadResult.url
    }
    
    // 프로필 이미지 업로드 (최적화됨)
    func uploadProfileImage(_ image: UIImage, userId: UUID) async throws -> (url: String, path: String) {
        os.Logger.info("uploadProfileImage 시작")
        
        // 프로필 이미지 최적화: 300x300 정사각형으로 크롭/리사이징 (더 공격적 압축)
        let optimizedImage = image.optimizedForProfile(size: 300)
        
        // JPEG 압축 (0.5 품질로 용량 대폭 감소 - 프로필용으로 충분)
        guard let imageData = optimizedImage.optimizedJPEGData(compressionQuality: 0.5) else {
            os.Logger.info("uploadProfileImage 실패: 프로필 이미지 JPEG 변환 실패")
            throw MemoryError.invalidImageData
        }
        
        // 최적화된 용량 로깅
        let originalSize = image.pngData()?.count ?? 0
        let optimizedSize = imageData.count
        os.Logger.info("uploadProfileImage 이미지 최적화: \(originalSize) bytes → \(optimizedSize) bytes (압축률: \(String(format: "%.1f", Double(optimizedSize) / Double(originalSize) * 100))%)")
        
        let fileName = "\(UUID().uuidString).jpg"
        let path = "\(userId.uuidString)/\(fileName)"
        let uploadResult = try await uploadToB2(data: imageData,
                                                folder: "profiles",
                                                fileExtension: "jpg",
                                                userId: userId,
                                                mimeType: "image/jpeg",
                                                customFileName: fileName)
        os.Logger.info("uploadProfileImage 완료 - public URL: \(uploadResult.url)")
        return (url: uploadResult.url, path: path)
    }
    
    // MARK: - Private Helpers
    
    /// 동영상 검증, 압축 및 메타데이터 추출 
    private func validateAndExtractMetadata(from data: Data) async throws -> (Data, Memory.SpatialMetadata?) {
        os.Logger.info("validateAndExtractMetadata 시작")
        let tempFileURL = try await createTempFile(with: data)
        os.Logger.info("Temporary file created: \(tempFileURL.path)")
        defer {
            try? FileManager.default.removeItem(at: tempFileURL)
            os.Logger.info("Temporary file deleted: \(tempFileURL.path)")
        }
        
        let asset = AVURLAsset(url: tempFileURL)
        guard try await validateMVHEVC(asset: asset) else {
            os.Logger.info("MV-HEVC 포맷 검증 실패")
            throw MediaError.invalidFormat
        }
        let metadata = try await extractSpatialMetadata(from: asset)
        os.Logger.info("메타데이터 추출 완료")
        
        // 공간 비디오는 원본 그대로 업로드
        os.Logger.info("Spatial video original upload: \(data.count) bytes")
        return (data, metadata)
    }
    

    
    /// 파일 업로드: 크기에 따라 단일/멀티파트 업로드 선택
    private func uploadToB2(data: Data, folder: String, fileExtension: String, userId: UUID, mimeType: String, customFileName: String? = nil, progressCallback: UploadProgressCallback? = nil) async throws -> (url: String, path: String) {
        let fileName = customFileName ?? "\(UUID().uuidString).\(fileExtension)"
        let path = "\(folder)/\(userId.uuidString)/\(fileName)"
        
        let multipartThreshold = 100 * 1024 * 1024
        
        if data.count >= multipartThreshold {
            return try await uploadLargeFile(fileName: fileName, path: path, data: data, mimeType: mimeType, userId: userId, progressCallback: progressCallback)
        } else {
            return try await uploadSingleFile(fileName: fileName, path: path, data: data, mimeType: mimeType, progressCallback: progressCallback)
        }
    }
    
    /// 단일 파일 업로드 (기존 로직 + 진행률)
    private func uploadSingleFile(fileName: String, path: String, data: Data, mimeType: String, progressCallback: UploadProgressCallback? = nil) async throws -> (url: String, path: String) {
        // 1. B2 인증
        progressCallback?(0.2, "Authenticating...")
        let (accountAuthToken, apiUrl, _) = try await b2Authorize()
        
        // 2. 업로드 URL 요청
        progressCallback?(0.3, "Requesting Upload URL...")
        let (uploadUrl, uploadAuthToken) = try await b2GetUploadURL(bucketId: b2BucketId, accountAuthToken: accountAuthToken, apiUrl: apiUrl)
        
        // 3. 파일 업로드
        progressCallback?(0.4, "Uploading files...")
        try await b2UploadFile(uploadUrl: uploadUrl, uploadAuthToken: uploadAuthToken, fileName: path, data: data, mimeType: mimeType, progressCallback: progressCallback)
        
        // 4. URL 구성
        let publicURL = "\(cloudflareDomain)/\(bucketName)/\(path)"
        os.Logger.info("✅ Single upload completed - URL: \(publicURL)")
        return (url: publicURL, path: path)
    }
    
    /// 멀티파트 업로드 (대용량 파일용 - 2-3배 빠름)
    private func uploadLargeFile(fileName: String, path: String, data: Data, mimeType: String, userId: UUID, progressCallback: UploadProgressCallback? = nil) async throws -> (url: String, path: String) {
        
        let chunkSize = 10 * 1024 * 1024 // 10MB 청크 (안정성을 위해 20MB에서 10MB로 조정)
        let totalChunks = (data.count + chunkSize - 1) / chunkSize
        
        // 1. B2 인증
        progressCallback?(0.2, "Authenticating...")
        let (accountAuthToken, apiUrl, _) = try await b2Authorize()
        
        // 2. 멀티파트 업로드 시작
        progressCallback?(0.25, "Preparing")
        let fileId = try await b2StartLargeFile(fileName: path, mimeType: mimeType, accountAuthToken: accountAuthToken, apiUrl: apiUrl)
        
        // 3. 각 청크를 순차적으로 업로드 (안정성을 위해 병렬 업로드 제거)
        var uploadedParts: [(partNumber: Int, sha1: String)] = []
        var completedChunks = 0
        
        for i in 0..<totalChunks {
            let chunkData = getChunkData(from: data, chunkIndex: i, chunkSize: chunkSize)
            
            // 진행률 업데이트 (0.3 ~ 0.9)
            let progress = 0.3 + (Double(completedChunks) / Double(totalChunks)) * 0.6
            let progressMessage = "Uploading... (\(completedChunks)/\(totalChunks) chunks)"
            progressCallback?(progress, progressMessage)
            
            // 청크 업로드 (재시도 로직 포함)
            let (partNumber, sha1) = try await uploadChunkWithRetry(
                fileId: fileId,
                partNumber: i + 1,
                data: chunkData,
                accountAuthToken: accountAuthToken,
                apiUrl: apiUrl
            )
            
            uploadedParts.append((partNumber: partNumber, sha1: sha1))
            completedChunks += 1
        }
        
        // 4. 멀티파트 업로드 완료
        progressCallback?(0.95, "Combining Files...")
        uploadedParts.sort { $0.partNumber < $1.partNumber }
        let sha1Array = uploadedParts.map { $0.sha1 }
        
        try await b2FinishLargeFile(fileId: fileId, sha1Array: sha1Array, accountAuthToken: accountAuthToken, apiUrl: apiUrl)
        
        // 5. URL 구성
        let publicURL = "\(cloudflareDomain)/\(bucketName)/\(path)"
        
        return (url: publicURL, path: path)
    }
    
    /// 청크 데이터 추출
    private func getChunkData(from data: Data, chunkIndex: Int, chunkSize: Int) -> Data {
        let startIndex = chunkIndex * chunkSize
        let endIndex = min(startIndex + chunkSize, data.count)
        let chunkData = data.subdata(in: startIndex..<endIndex)
        
        // 마지막 청크가 5MB 미만인 경우 경고
        let totalChunks = (data.count + chunkSize - 1) / chunkSize
        if chunkIndex == totalChunks - 1 && chunkData.count < 5 * 1024 * 1024 {
            os.Logger.warning("⚠️ Final chunk size is less than 5MB: \(chunkData.count) bytes")
            os.Logger.warning("⚠️ This may cause B2 upload issues. Consider increasing chunk size.")
        }
        
        return chunkData
    }
    
    /// 개별 청크 업로드 (재시도 로직 포함)
    private func uploadChunkWithRetry(fileId: String, partNumber: Int, data: Data, accountAuthToken: String, apiUrl: String) async throws -> (Int, String) {
        let maxRetries = 3
        var currentRetry = 0
        var lastError: Error?
        
        while currentRetry < maxRetries {
            do {
                // B2 청크 업로드 URL 획득
                let (uploadUrl, uploadAuthToken) = try await b2GetUploadPartUrl(fileId: fileId, accountAuthToken: accountAuthToken, apiUrl: apiUrl)
                
                // 청크 업로드 및 SHA1 반환
                let sha1 = try await b2UploadPart(uploadUrl: uploadUrl, authToken: uploadAuthToken, partNumber: partNumber, data: data)
                
                return (partNumber, sha1)
            } catch {
                lastError = error
                currentRetry += 1
                
                if currentRetry < maxRetries {
                    os.Logger.warning("🔄 Chunk \(partNumber) upload failed, retrying (\(currentRetry)/\(maxRetries)): \(error.localizedDescription)")
                    let delay = pow(2.0, Double(currentRetry - 1)) // 1s, 2s, 4s
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    continue
                }
            }
        }
        
        throw lastError ?? MediaError.uploadFailed(message: "Chunk \(partNumber) upload failed")
    }
    
    /// 개별 청크 업로드 (기존 함수 - 재시도 로직 없음)
    private func uploadChunk(fileId: String, partNumber: Int, data: Data, accountAuthToken: String, apiUrl: String) async throws -> (Int, String) {
        // B2 청크 업로드 URL 획득
        let (uploadUrl, uploadAuthToken) = try await b2GetUploadPartUrl(fileId: fileId, accountAuthToken: accountAuthToken, apiUrl: apiUrl)
        
        // 청크 업로드 및 SHA1 반환
        let sha1 = try await b2UploadPart(uploadUrl: uploadUrl, authToken: uploadAuthToken, partNumber: partNumber, data: data)
        
        return (partNumber, sha1)
    }
    
    /// 임시 파일 생성 (메모리 최적화)
    private func createTempFile(with data: Data) async throws -> URL {
        let tempDirectory = FileManager.default.temporaryDirectory
        let tempFileURL = tempDirectory.appendingPathComponent("\(UUID().uuidString).mov")
        
        // 큰 파일을 위한 메모리 효율적 쓰기
        os.Logger.info("💾 Creating temporary file... (\(data.count) bytes)")
        try data.write(to: tempFileURL, options: [.atomic, .noFileProtection])
        os.Logger.info("✅ Temporary file created: \(tempFileURL.lastPathComponent)")
        
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
        let cleanedKeyID = b2KeyID.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanedAppKey = b2ApplicationKey.trimmingCharacters(in: .whitespacesAndNewlines)
        let authString = "\(cleanedKeyID):\(cleanedAppKey)"
        let base64Auth = Data(authString.utf8).base64EncodedString()
        Logger.info("🪪 인코딩 전 문자열: [\(authString)]")
        Logger.info("🔐 Base64 인코딩 결과: \(base64Auth)")
        guard let authData = authString.data(using: .utf8) else {
            throw MediaError.uploadFailed()
        }
        os.Logger.info(base64Auth)
        
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
    private func b2UploadFile(uploadUrl: String, uploadAuthToken: String, fileName: String, data: Data, mimeType: String, progressCallback: UploadProgressCallback? = nil) async throws {
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
                
                // Always calculate SHA1 hash for security
                let digest = Insecure.SHA1.hash(data: data)
                let sha1Hash = digest.map { String(format: "%02x", $0) }.joined()
                request.setValue(sha1Hash, forHTTPHeaderField: "X-Bz-Content-Sha1")
                request.httpMethod = "POST"
                
                // 네트워크 최적화 설정
                let configuration = URLSessionConfiguration.default
                configuration.timeoutIntervalForResource = 7200 // 2시간 (큰 파일용)
                configuration.timeoutIntervalForRequest = 300   // 5분 (요청 타임아웃)
                configuration.httpMaximumConnectionsPerHost = 6  // 동시 연결 수 증가
                configuration.allowsCellularAccess = true       // 셀룰러 허용
                configuration.waitsForConnectivity = false      // 연결 대기 비활성화 (빠른 실패)
                configuration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData // 캐시 무시
                let session = URLSession(configuration: configuration)
                
                os.Logger.info("🚀 b2_upload_file 시작 - 파일 크기: \(data.count) bytes, 시도: \(currentRetry + 1)/\(maxRetries)")
                
                // 업로드 시작 진행률 업데이트
                progressCallback?(0.5, "파일 전송 중...")
                
                // 백그라운드 업로드 가능한 uploadTask 사용 (진행률 추적 가능)
                let (responseData, response) = try await session.upload(for: request, from: data)
                
                // 업로드 완료 진행률 업데이트
                progressCallback?(0.9, "업로드 검증 중...")
                os.Logger.info("✅ b2_upload_file 응답 받음 - 응답 크기: \(responseData.count) bytes")
                
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200 {
                        os.Logger.info("b2_upload_file 성공")
                        return // 성공하면 함수 종료
                    } else {
                        if let errorString = String(data: responseData, encoding: .utf8) {
                            os.Logger.error("b2_upload_file 실패 - HTTP 응답 코드: \(httpResponse.statusCode), 에러: \(errorString)")
                        }
                        
                        // 🧠 스마트 재시도 로직 (에러 타입별 차별화)
                        let (shouldRetry, retryDelay) = getRetryStrategy(for: httpResponse.statusCode)
                        
                        if shouldRetry {
                            currentRetry += 1
                            if currentRetry < maxRetries {
                                os.Logger.info("🔄 \(getRetryMessage(for: httpResponse.statusCode)) - 시도 \(currentRetry)/\(maxRetries), \(retryDelay)초 대기")
                                try await Task.sleep(nanoseconds: UInt64(retryDelay * 1_000_000_000))
                                continue
                            }
                        }
                        
                        throw MediaError.uploadFailed(message: "업로드 실패 (HTTP \(httpResponse.statusCode))")
                    }
                } else {
                    throw MediaError.uploadFailed()
                }
            } catch {
                os.Logger.error("b2_upload_file 에러 발생: \(error.localizedDescription)")
                currentRetry += 1
                if currentRetry >= maxRetries {
                    os.Logger.error("b2_upload_file 최대 재시도 횟수 초과 - 에러: \(error)")
                    throw error
                }
                os.Logger.info("b2_upload_file 재시도 중... (시도 \(currentRetry)/\(maxRetries)) - 에러: \(error.localizedDescription)")
                try await Task.sleep(nanoseconds: UInt64(pow(2.0, Double(currentRetry)) * 1_000_000_000))
            }
        }
        
        throw MediaError.uploadFailed(message: "최대 재시도 횟수 초과")
    }
    
    // MARK: - 스마트 재시도 전략
    
    /// HTTP 상태 코드에 따른 재시도 전략 결정
    private func getRetryStrategy(for statusCode: Int) -> (shouldRetry: Bool, delay: Double) {
        switch statusCode {
        case 429: // Too Many Requests - 빠른 재시도
            return (true, 0.5)
            
        case 408: // Request Timeout - 즉시 재시도
            return (true, 0.2)
            
        case 500, 502, 503, 504: // 서버 오류 - 중간 대기
            return (true, 2.0)
            
        case 520...526: // Cloudflare 오류 - 긴 대기
            return (true, 5.0)
            
        default: // 재시도 불가능
            return (false, 0)
        }
    }
    
    /// 재시도 메시지 생성
    private func getRetryMessage(for statusCode: Int) -> String {
        switch statusCode {
        case 429: return "요청 한도 초과, 재시도"
        case 408: return "요청 타임아웃, 재시도"
        case 500: return "내부 서버 오류, 재시도"
        case 502: return "게이트웨이 오류, 재시도"
        case 503: return "서비스 사용 불가, 재시도"
        case 504: return "게이트웨이 타임아웃, 재시도"
        case 520...526: return "Cloudflare 오류, 재시도"
        default: return "HTTP \(statusCode) 오류"
        }
    }
    
    // MARK: - B2 멀티파트 업로드 API
    
    /// 멀티파트 업로드 시작
    private func b2StartLargeFile(fileName: String, mimeType: String, accountAuthToken: String, apiUrl: String) async throws -> String {
        guard let url = URL(string: "\(apiUrl)/b2api/v2/b2_start_large_file") else {
            throw MediaError.uploadFailed(message: "Invalid API URL: \(apiUrl)")
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(accountAuthToken, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload = [
            "bucketId": b2BucketId,
            "fileName": fileName,
            "contentType": mimeType
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            guard httpResponse.statusCode == 200 else {
                throw MediaError.uploadFailed(message: "b2_start_large_file 실패: HTTP \(httpResponse.statusCode)")
            }
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let fileId = json["fileId"] as? String else {
            throw MediaError.uploadFailed(message: "b2_start_large_file 응답 파싱 실패")
        }
        
        os.Logger.info("✅ b2_start_large_file 성공 - fileId: \(fileId)")
        return fileId
    }
    
    /// 청크 업로드 URL 획득
    private func b2GetUploadPartUrl(fileId: String, accountAuthToken: String, apiUrl: String) async throws -> (url: String, authToken: String) {
        guard let url = URL(string: "\(apiUrl)/b2api/v2/b2_get_upload_part_url") else {
            throw MediaError.uploadFailed(message: "Invalid API URL: \(apiUrl)")
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(accountAuthToken, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload = ["fileId": fileId]
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            guard httpResponse.statusCode == 200 else {
                throw MediaError.uploadFailed(message: "b2_get_upload_part_url 실패: HTTP \(httpResponse.statusCode)")
            }
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let uploadUrl = json["uploadUrl"] as? String,
              let uploadAuthToken = json["authorizationToken"] as? String else {
            throw MediaError.uploadFailed(message: "b2_get_upload_part_url 응답 파싱 실패")
        }
        
        return (url: uploadUrl, authToken: uploadAuthToken)
    }
    
    /// 개별 청크 업로드
    private func b2UploadPart(uploadUrl: String, authToken: String, partNumber: Int, data: Data) async throws -> String {
        // B2 청크 크기 검증 (5MB ~ 5GB)
        let minChunkSize = 5 * 1024 * 1024 // 5MB
        let maxChunkSize = 5 * 1024 * 1024 * 1024 // 5GB
        
        guard data.count >= minChunkSize else {
            throw MediaError.uploadFailed(message: "Chunk size too small. Minimum 5MB required, current: \(data.count) bytes")
        }
        
        guard data.count <= maxChunkSize else {
            throw MediaError.uploadFailed(message: "Chunk size too large. Maximum 5GB, current: \(data.count) bytes")
        }
        
        guard let url = URL(string: uploadUrl) else {
            throw MediaError.uploadFailed(message: "Invalid upload URL: \(uploadUrl)")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(authToken, forHTTPHeaderField: "Authorization")
        request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
        request.setValue(String(partNumber), forHTTPHeaderField: "X-Bz-Part-Number")
        request.setValue(String(data.count), forHTTPHeaderField: "Content-Length")
        
        // Always calculate SHA1 hash for security
        let digest = Insecure.SHA1.hash(data: data)
        let sha1Hash = digest.map { String(format: "%02x", $0) }.joined()
        
        request.setValue(sha1Hash, forHTTPHeaderField: "X-Bz-Content-Sha1")
        
        let (responseData, response) = try await URLSession.shared.upload(for: request, from: data)
        
        if let httpResponse = response as? HTTPURLResponse {
            guard httpResponse.statusCode == 200 else {
                throw MediaError.uploadFailed(message: "b2_upload_part 실패: HTTP \(httpResponse.statusCode)")
            }
        }
        
        guard let json = try JSONSerialization.jsonObject(with: responseData) as? [String: Any],
              let contentSha1 = json["contentSha1"] as? String else {
            // SHA1이 없으면 계산된 해시 반환
            return sha1Hash
        }
        
        return contentSha1
    }
    
    /// 멀티파트 업로드 완료
    private func b2FinishLargeFile(fileId: String, sha1Array: [String], accountAuthToken: String, apiUrl: String) async throws {
        guard let url = URL(string: "\(apiUrl)/b2api/v2/b2_finish_large_file") else {
            throw MediaError.uploadFailed(message: "Invalid API URL: \(apiUrl)")
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(accountAuthToken, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload = [
            "fileId": fileId,
            "partSha1Array": sha1Array
        ] as [String: Any]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            guard httpResponse.statusCode == 200 else {
                if let errorString = String(data: data, encoding: .utf8) {
                    os.Logger.error("b2_finish_large_file 에러: \(errorString)")
                }
                throw MediaError.uploadFailed(message: "b2_finish_large_file 실패: HTTP \(httpResponse.statusCode)")
            }
        }
        
        os.Logger.info("✅ b2_finish_large_file 성공")
    }
}

enum MediaError: LocalizedError {
    case invalidFormat
    case metadataExtractionFailed
    case uploadFailed(message: String? = nil)
    
    var errorDescription: String? {
        switch self {
        case .invalidFormat:
            return "Video format is invalid. Please check if it's a Spatial Video format."
        case .metadataExtractionFailed:
            return "Failed to extract metadata."
        case .uploadFailed(let message):
            return message ?? "Video upload failed."
        }
    }
}
