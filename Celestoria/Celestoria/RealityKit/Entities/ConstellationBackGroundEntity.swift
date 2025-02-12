//
//  ConstellationBackGroundEntity.swift
//  Celestoria
//
//  Created by Park Seyoung on 1/20/25.
//

import SwiftUI
import RealityKit
import RealityKitContent

@MainActor
class ConstellationBackgroundEntity: Entity {
    // MARK: - Constants
    private enum Constants {
        static let sphereRadius: Float = 1000
//        static let textureName = "Starfield"
        static let scaleX: Float = -1  
        static let scaleY: Float = 1
        static let scaleZ: Float = 1
    }
    
    // MARK: - Initialization
    required init() {
        super.init()
        setupBackground()
    }
    
    // MARK: - Setup
    private func setupBackground() {
        // 1. 거대한 구체 메시 생성
        let sphereMesh = MeshResource.generateSphere(
            radius: Constants.sphereRadius
        )
        
        // 2. 스타필드 텍스처 로드
//        let material = createStarfieldMaterial()
        
        // 3. 구체 엔티티 생성 및 설정
        let sphereEntity = ModelEntity(
            mesh: sphereMesh
//            materials: [material]
        )
        
        // 4. 텍스처를 안쪽으로 보이도록 x축 스케일 반전
        sphereEntity.scale *= .init(
            x: Constants.scaleX,
            y: Constants.scaleY,
            z: Constants.scaleZ
        )
        
        // 5. 배경 구체를 자식으로 추가
        addChild(sphereEntity)
    }
    
//    private func createStarfieldMaterial() -> UnlitMaterial {
//        guard let textureResource = try? TextureResource.load(
//            named: Constants.textureName
//        ) else {
//            fatalError("Failed to load \(Constants.textureName) texture.")
//        }
//
//        var material = UnlitMaterial()
//        material.color = .init(texture: .init(textureResource))
//        return material
//    }
}
