//
//  EntityPool.swift
//  Celestoria
//
//  Created by Minjun Kim on 7/15/25.
//


//
//  EntityPool.swift
//  Celestoria
//
//  Created by Assistant on 1/16/25.
//

import RealityKit
import os

/// 엔티티 재사용을 위한 풀 관리자
@MainActor
final class EntityPool<T: Entity> {
    private var availableEntities: [T] = []
    private var activeEntities: Set<T> = []
    private let maxPoolSize: Int
    private let logger = Logger(subsystem: "Celestoria", category: "EntityPool")
    
    private let createEntity: () -> T
    
    init(maxPoolSize: Int = 50, createEntity: @escaping () -> T) {
        self.maxPoolSize = maxPoolSize
        self.createEntity = createEntity
    }
    
    /// 풀에서 엔티티를 가져옵니다
    func acquire() -> T {
        let entity: T
        
        if let available = availableEntities.popLast() {
            entity = available
            logger.debug("Reusing entity from pool")
        } else {
            entity = createEntity()
            logger.debug("Creating new entity")
        }
        
        activeEntities.insert(entity)
        return entity
    }
    
    /// 엔티티를 풀로 반환합니다
    func release(_ entity: T) {
        guard activeEntities.contains(entity) else {
            logger.warning("Attempted to release entity not from this pool")
            return
        }
        
        activeEntities.remove(entity)
        entity.removeFromParent()
        
        // 풀 크기 제한 확인
        if availableEntities.count < maxPoolSize {
            resetEntity(entity)
            availableEntities.append(entity)
            logger.debug("Entity returned to pool")
        } else {
            logger.debug("Pool full, entity discarded")
        }
    }
    
    /// 모든 엔티티를 정리합니다
    func clear() {
        activeEntities.forEach { $0.removeFromParent() }
        activeEntities.removeAll()
        availableEntities.removeAll()
        logger.info("Entity pool cleared")
    }
    
    /// 엔티티를 초기 상태로 리셋합니다
    private func resetEntity(_ entity: T) {
        entity.position = .zero
        entity.orientation = .init(angle: 0, axis: [0, 1, 0])
        entity.scale = .one
        
        // 자식 엔티티 제거
        entity.children.forEach { $0.removeFromParent() }
    }
    
    var activeCount: Int { activeEntities.count }
    var availableCount: Int { availableEntities.count }
}