//
//  MemoryStarEntity.swift
//  Celestoria
//
//  Created by Park Seyoung on 1/20/25.
//

import SwiftUI
import Combine
import RealityKit
import RealityKitContent
import AVFoundation

// MARK: - MemoryStarEntity
@MainActor
class MemoryStarEntity: Entity, HasModel, HasCollision {
    // MARK: - Properties
    let memory: Memory
    
    private enum Constants {
        static let videoOffset = SIMD3<Float>(0, 0.5, 0)
        static let starRadius: Float = 0.1
        static let pulseScale = SIMD3<Float>(3.2, 3.2, 3.2)
        static let initialScale = SIMD3<Float>(3, 3, 3)
    }
    
    var videoPosition: SIMD3<Float> {
        position + Constants.videoOffset
    }
    
    // MARK: - Initialization
    init(memory: Memory, position: SIMD3<Float>) {
        self.memory = memory
        super.init()
        self.transform.scale = Constants.initialScale
        self.position = position
        
        // 필수 컴포넌트 추가
        self.components[CollisionComponent.self] = CollisionComponent(
            shapes: [.generateSphere(radius: Constants.starRadius)]
        )
        self.components[HoverEffectComponent.self] = HoverEffectComponent()
        self.components[InputTargetComponent.self] = InputTargetComponent(
            allowedInputTypes: .indirect
        )

        addBlinkingAnimation()
    }
    
    required init() {
        fatalError("init() has not been implemented")
    }
    
    // MARK: - Animation
    private func addBlinkingAnimation() {
        var transform = self.transform
        transform.scale = Constants.pulseScale
        
        let animationDefinition = FromToByAnimation(
            to: transform,
            bindTarget: .transform
        )
        
        let animationResource = try! AnimationResource.generate(with: animationDefinition)
        self.playAnimation(animationResource.repeat(duration: .infinity))
    }
    
    func loadModel(for category: Category) async {
        let modelName = category.modelFileName
        do {
            // Load model
            let modelEntity = try await ModelEntity(named: modelName)
            
            // ENTERTAINMENT 카테고리인 경우 180도 회전
            if category == .ENTERTAINMENT {
                modelEntity.orientation = simd_quatf(angle: .pi, axis: [0, 1, 0])  // Y축을 기준으로 180도 회전
            }
            
            // Add collision components & interaction effects
            modelEntity.generateCollisionShapes(recursive: true)
            modelEntity.components[HoverEffectComponent.self] = HoverEffectComponent(.spotlight(
                HoverEffectComponent.SpotlightHoverEffectStyle(
                    color: UIColor(Color(hex: "A7E9FE")), strength: 10.0
                )
            ))
            modelEntity.components[InputTargetComponent.self] = InputTargetComponent(allowedInputTypes: .indirect)
            
            // Attach to parent entity
            self.addChild(modelEntity)
        } catch {
            print("Failed to load model '\(modelName)': \(error.localizedDescription)")
        }
    }
}
