//
//  ReportAndBlockUseCase.swift
//  Celestoria
//
//  Created by AI Assistant on 2025.
//

import Foundation
import os

struct ReportAndBlockUseCase {
    private let memoryRepository: MemoryRepository
    private let authRepository: AuthRepositoryProtocol
    private let logger = Logger(subsystem: "com.celestoria", category: "ReportAndBlockUseCase")
    
    init(memoryRepository: MemoryRepository, authRepository: AuthRepositoryProtocol) {
        self.memoryRepository = memoryRepository
        self.authRepository = authRepository
    }
    
    // 메모리 신고
    func reportMemory(memoryId: UUID, reporterId: UUID) async throws {
        do {
            try await memoryRepository.createReport(memoryId: memoryId, reporterId: reporterId)
            logger.info("Memory reported successfully: \(memoryId)")
        } catch {
            logger.error("Failed to report memory: \(error.localizedDescription)")
            throw error
        }
    }
    
    // 사용자 차단
    func blockUser(reporterId: UUID, blockedUserId: UUID) async throws {
        do {
            try await authRepository.blockUser(reporterId: reporterId, blockedUserId: blockedUserId)
            logger.info("User blocked successfully: \(blockedUserId)")
        } catch {
            logger.error("Failed to block user: \(error.localizedDescription)")
            throw error
        }
    }
    
    // 이미 신고한 메모리인지 확인
    func hasReportedMemory(memoryId: UUID, reporterId: UUID) async throws -> Bool {
        do {
            return try await memoryRepository.hasReported(memoryId: memoryId, reporterId: reporterId)
        } catch {
            logger.error("Failed to check if memory is reported: \(error.localizedDescription)")
            throw error
        }
    }
}
