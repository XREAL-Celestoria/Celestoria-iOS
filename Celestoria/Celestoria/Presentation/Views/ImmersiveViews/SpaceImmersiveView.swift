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

                spaceCoordinator.initialize()


                if let spaceEntity = spaceCoordinator.spaceEntity {
                    content.add(spaceEntity)
                    os.Logger.info("SpaceImmersiveView: Added spaceEntity to RealityView")
                }
            }
            .gesture(starTapGesture) // Handle gestures for user interaction
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
}
