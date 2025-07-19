//
//  BackgroundManager.swift
//  Celestoria
//
//  Created by Minjun Kim on 7/15/25.
//


//
//  BackgroundManager.swift
//  Celestoria
//
//  Created by Assistant on 1/16/25.
//

import RealityKit
import SwiftUI
import os

/// 배경 관리를 전담하는 매니저
@MainActor
final class BackgroundManager {
    private var backgroundEntity: SpaceBackgroundEntity?
    private var currentBackgroundName: String?
    private let logger = Logger(subsystem: "Celestoria", category: "BackgroundManager")
    
    // MARK: - Public Methods
    
    /// 배경을 초기화합니다
    func setupBackground(imageName: String, in spaceEntity: SpaceEntity) {
        // 이미 같은 배경이면 무시
        if currentBackgroundName == imageName {
            return
        }
        
        removeCurrentBackground()
        let background = SpaceBackgroundEntity(backgroundImageName: imageName)
        spaceEntity.addChild(background)
        backgroundEntity = background
        currentBackgroundName = imageName
        logger.info("Background set up with image: \(imageName)")
    }
    
    /// 배경 텍스처를 업데이트합니다
    func updateBackground(imageName: String) {
        // 이미 같은 배경이면 무시
        if currentBackgroundName == imageName {
            // Debug 레벨로 변경하여 불필요한 로그 감소
            return
        }
        
        guard let backgroundEntity = backgroundEntity else {
            logger.error("Background entity not found")
            return
        }
        
        backgroundEntity.updateTexture(with: imageName)
        currentBackgroundName = imageName
        logger.info("Background updated to: \(imageName)")
    }
    
    /// 현재 배경을 제거합니다
    func removeCurrentBackground() {
        backgroundEntity?.removeFromParent()
        backgroundEntity = nil
        currentBackgroundName = nil
    }
}