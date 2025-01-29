//
//  SpaceImmersiveView.swift
//  Celestoria
//
//  Created by Minjun Kim on 1/16/25.
//

import SwiftUI
import RealityKit
import os

struct SpaceImmersiveView: View {
    @Environment(\.openWindow) private var openWindow
    @EnvironmentObject var spaceCoordinator: SpaceCoordinator

    var body: some View {
        ZStack {
            RealityView { content in
                os.Logger.info("SpaceImmersiveView: Setting up RealityView")
                content.entities.removeAll()
                
                // spaceCoordinator를 초기화하고 엔티티를 추가합니다.
                initializeAndAddEntity(to: content)
            }
            .gesture(starTapGesture)
        }
    }

    // MARK: - Gesture Handling
    private var starTapGesture: some Gesture {
        SpatialTapGesture()
            .targetedToAnyEntity()
            .onEnded { value in
                os.Logger.info("Star tapped!")
                if let modelEntity = value.entity as? ModelEntity,
                   let starEntity = modelEntity.parent as? MemoryStarEntity {
                    let mem = starEntity.memory
                    print("[DEBUG] Tapped Star's Memory => id: \(mem.id), title: \(mem.title), video: \(mem.videoURL ?? "nil")")
                    
                    AudioServicesPlaySystemSound(1104)
                    Task { @MainActor in
                        await openMemoryDetailView(for: starEntity)
                    }
                } else {
                    os.Logger.error("Failed to cast entity to MemoryStarEntity")
                }
            }
    }

    private func openMemoryDetailView(for starEntity: MemoryStarEntity) async {
        openWindow(value: starEntity.memory)
    }
    
    private func initializeAndAddEntity(to content: RealityViewContent) {
            Task {
                await spaceCoordinator.initialize()

                if let spaceEntity = spaceCoordinator.spaceEntity {
                    content.add(spaceEntity)
                    os.Logger.info("SpaceImmersiveView: Added spaceEntity to RealityView")
                }
            }
        }
}
