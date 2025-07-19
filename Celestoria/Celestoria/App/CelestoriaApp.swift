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
    @State private var currentStyle: ImmersionStyle = .full

    var body: some Scene {
        WindowGroup("Main", id: "Main") {
            ContentView()
                .frame(width: 1280, height: 720)
                .environmentObject(diContainer.appModel)
                .environmentObject(diContainer.appState)
                .environmentObject(diContainer.appState.spaceCoordinator)
                .environmentObject(diContainer.appState.mainViewModel)
                .environmentObject(diContainer.appState.loginViewModel!)
                .environmentObject(diContainer.settingViewModel)
                .environmentObject(diContainer.galaxyViewModel)
                .environmentObject(diContainer.exploreViewModel)
        }
        .windowResizability(.contentSize)

        ImmersiveSpace(id: diContainer.appState.immersiveSpaceID) {
            SpaceImmersiveView()
                .environmentObject(diContainer.appState.spaceCoordinator)
        }.immersionStyle(selection: $currentStyle, in: .full)

        WindowGroup("Add Memory", id: "Add-Memory") {
            if diContainer.appState.showAddMemoryView {
                AddMemoryContentView()
                    .frame(width: 1280, height: 720)
                    .environmentObject(diContainer.appModel)
                    .environmentObject(diContainer.appState)
                    .environmentObject(diContainer.appState.mainViewModel)
                    .environmentObject(diContainer.appState.spaceCoordinator)
                    .environmentObject(diContainer.addMemoryMainViewModel)
            }
        }
        .windowResizability(.contentSize)

        // MemoryDetailView를 직접 사용하여 단일 파일로 관리합니다.
        WindowGroup(id: "Memory-Detail", for: Memory.self) { $memory in
            if let memory = memory {
                MemoryDetailView(
                    memory: memory,
                    memoryRepository: diContainer.memoryRepository,
                    profileUseCase: diContainer.profileUseCase,
                    authRepository: diContainer.authRepository,
                    appModel: diContainer.appModel,
                    spaceCoordinator: diContainer.appState.spaceCoordinator
                )
                .frame(width: 1280, height: 720)
                .environmentObject(diContainer.appModel)
                .environmentObject(diContainer.appState)
                .environmentObject(diContainer.appState.spaceCoordinator)
            } else {
                EmptyView()
            }
        }
        .windowResizability(.contentSize)
        
        WindowGroup(id: "Explore-Navigator", for: UUID.self) { $profileId in
            if let profileId = profileId {
                ExploreNavigatorView(profileId: profileId)
                    .frame(width: 720, height: 188)
                    .environmentObject(diContainer.appModel)
                    .environmentObject(diContainer.appState)
                    .environmentObject(diContainer.appState.spaceCoordinator)
                    .environmentObject(diContainer.exploreViewModel)
            } else {
                Text("No user selected.")
                    .frame(width: 720, height: 188)
            }
        }
        .windowResizability(.contentSize)
    }
}
