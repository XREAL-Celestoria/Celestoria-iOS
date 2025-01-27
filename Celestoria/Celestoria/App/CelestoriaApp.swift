//
//  CelestoriaApp.swift
//  Celestoria
//
//  Created by Minjun Kim on 1/16/25.
//

// 앱의 진입점, DIContainer 사용하여 의존성 제공
import SwiftUI

@main
struct CelestoriaApp: App {
    @StateObject private var diContainer = DIContainer()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(width: 1280, height: 720)
                .environmentObject(diContainer.appModel)
                .environmentObject(diContainer.mainViewModel)
                .environmentObject(diContainer.loginViewModel)
                .environmentObject(diContainer.settingViewModel)
                .environmentObject(diContainer.galaxyViewModel)
        }
        .windowResizability(.contentSize)

        ImmersiveSpace(id: diContainer.appModel.immersiveSpaceID) {
            SpaceImmersiveView()
                .environmentObject(diContainer.spaceCoordinator)
        }

        WindowGroup("Add Memory", id: "Add-Memory") {
            if diContainer.appModel.showAddMemoryView {
                AddMemoryContentView()
                    .frame(width: 1280, height: 720)
                    .environmentObject(diContainer.appModel)
                    .environmentObject(diContainer.addMemoryMainViewModel)
                    .environmentObject(diContainer.mainViewModel)
                    .environmentObject(diContainer.spaceCoordinator)
            }
        }
        .windowResizability(.contentSize)

        WindowGroup(id: "Memory-Detail", for: Memory.self) { $memory in
            if let unwrappedMemory = $memory.wrappedValue {
                MemoryDetailView(memory: unwrappedMemory, memoryRepository: diContainer.memoryRepository)
                    .frame(width: 1280, height: 720)
                    .environmentObject(diContainer.appModel)
                    .environmentObject(diContainer.spaceCoordinator)
            } else {
                Text("No memory provided.")
                    .frame(width: 1280, height: 720)
            }
        }
        .windowResizability(.contentSize)
    }
}
