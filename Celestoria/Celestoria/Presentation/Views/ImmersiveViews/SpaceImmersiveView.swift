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
                os.Logger.space.debug("SpaceImmersiveView: Setting up RealityView")
                content.entities.removeAll()

                spaceCoordinator.initialize()


                if let spaceEntity = spaceCoordinator.spaceEntity {
                    content.add(spaceEntity)
                    os.Logger.space.debug("SpaceImmersiveView: Added spaceEntity to RealityView")
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
                os.Logger.space.debug("Star tapped!")
                if let modelEntity = value.entity as? ModelEntity,
                   let starEntity = modelEntity.parent as? MemoryStarEntity {
                    Task { @MainActor in
                        await openMemoryDetailView(for: starEntity)
                    }
                } else {
                    os.Logger.space.error("Failed to cast entity to MemoryStarEntity")
                    os.Logger.space.error("Actual entity type: \(type(of: value.entity))")
                }
            }
    }

    private func openMemoryDetailView(for starEntity: MemoryStarEntity) async {
        openWindow(value: starEntity.memory)
    }
}
