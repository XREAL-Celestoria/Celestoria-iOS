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
                .environmentObject(diContainer.spaceCoordinator)
                .environmentObject(diContainer.appModel)
                .environmentObject(diContainer.mainViewModel)
                .environmentObject(diContainer.loginViewModel)
                .environmentObject(diContainer.settingViewModel)
                .environmentObject(diContainer.galaxyViewModel)
                .environmentObject(diContainer.exploreViewModel)
        }
        .windowResizability(.contentSize)

        ImmersiveSpace(id: diContainer.appModel.immersiveSpaceID) {
            SpaceImmersiveView()
                .environmentObject(diContainer.spaceCoordinator)
        }.immersionStyle(selection: $currentStyle, in: .full)

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

        // MemoryDetailView를 직접 사용하여 단일 파일로 관리합니다.
        WindowGroup(id: "Memory-Detail", for: Memory.self) { $memory in
            if let memory = memory {
                MemoryDetailView(
                    memory: memory,
                    memoryRepository: diContainer.memoryRepository,
                    profileUseCase: diContainer.profileUseCase,
                    authRepository: diContainer.authRepository,
                    appModel: diContainer.appModel,
                    spaceCoordinator: diContainer.spaceCoordinator
                )
                .frame(width: 1280, height: 720)
                .environmentObject(diContainer.appModel)
                .environmentObject(diContainer.spaceCoordinator)
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
                    .environmentObject(diContainer.exploreViewModel)
                    .environmentObject(diContainer.spaceCoordinator)
            } else {
                Text("No user selected.")
                    .frame(width: 720, height: 188)
            }
        }
        .windowResizability(.contentSize)
    }
}
