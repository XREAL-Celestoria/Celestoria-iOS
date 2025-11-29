//
//  MemoryWindowManager.swift
//  Celestoria
//
//  Created by AI Assistant
//

import SwiftUI
import os

/// 메모리당 하나의 뷰만 열리도록 관리하는 유틸리티
@MainActor
class MemoryWindowManager {
    static let shared = MemoryWindowManager()
    
    // 현재 열려있는 메모리 ID들을 추적
    private var openMemoryIds: Set<UUID> = []
    private let logger = Logger(subsystem: "com.celestoria", category: "MemoryWindowManager")
    
    private init() {}
    
    /// 메모리 상세 뷰를 열기 (중복 방지)
    func openMemoryDetailView(memory: Memory, openWindow: OpenWindowAction) {
        let memoryId = memory.id
        
        // 이미 열려있는 경우, 새 창을 열지 않음
        if openMemoryIds.contains(memoryId) {
            logger.info("Memory \(memoryId) is already open. Skipping duplicate window.")
            return
        }
        
        // 새로 열기 (실제 추적은 onAppear에서 수행)
        openWindow(value: memory)
        logger.info("Requested to open MemoryDetailView for memory \(memoryId)")
    }
    
    /// 메모리 창이 열렸을 때 호출 (MemoryDetailView의 onAppear에서)
    func onMemoryWindowOpened(memoryId: UUID) {
        openMemoryIds.insert(memoryId)
        logger.info("MemoryDetailView opened for memory \(memoryId)")
    }
    
    /// 메모리 창이 닫혔을 때 호출 (MemoryDetailView의 onDisappear에서)
    func onMemoryWindowClosed(memoryId: UUID) {
        openMemoryIds.remove(memoryId)
        logger.info("MemoryDetailView closed for memory \(memoryId)")
    }
    
    /// 특정 메모리 창이 열려있는지 확인
    func isMemoryWindowOpen(memoryId: UUID) -> Bool {
        return openMemoryIds.contains(memoryId)
    }
}

