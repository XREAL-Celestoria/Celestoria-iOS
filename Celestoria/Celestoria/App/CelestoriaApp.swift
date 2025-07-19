//
//  CelestoriaApp.swift
//  Celestoria
//
//  Created by Minjun Kim on 1/16/25.
//

// 앱의 진입점, DIContainer 사용하여 의존성 제공
import SwiftUI
import os

@main
struct CelestoriaApp: App {
    @StateObject private var diContainer = DIContainer()
    @State private var currentStyle: ImmersionStyle = .full

    var body: some Scene {
        WindowGroup("Main", id: "Main") {
            Group {
                if let spaceCoordinator = diContainer.appState.spaceCoordinator,
                   let mainViewModel = diContainer.appState.mainViewModel,
                   let loginViewModel = diContainer.appState.loginViewModel {
                    ContentView()
                        .frame(width: 1280, height: 720)
                        .environmentObject(diContainer.appState)
                        .environmentObject(spaceCoordinator)
                        .environmentObject(mainViewModel)
                        .environmentObject(loginViewModel)
                        .environmentObject(diContainer.settingViewModel)
                        .environmentObject(diContainer.galaxyViewModel)
                        .environmentObject(diContainer.exploreViewModel)
                } else {
                    ProgressView("Loading...")
                        .frame(width: 1280, height: 720)
                        .onAppear {
                            os.Logger().error("🔴 ViewModels not initialized!")
                        }
                }
            }
        }
        .windowResizability(.contentSize)

        ImmersiveSpace(id: diContainer.appState.immersiveSpaceID) {
            if let spaceCoordinator = diContainer.appState.spaceCoordinator {
                SpaceImmersiveView()
                    .environmentObject(spaceCoordinator)
            } else {
                Text("Loading...")
                    .onAppear {
                        os.Logger().error("🔴 ImmersiveSpace: spaceCoordinator is nil!")
                    }
            }
        }.immersionStyle(selection: $currentStyle, in: .full)

        WindowGroup("Add Memory", id: "Add-Memory") {
            if diContainer.appState.showAddMemoryView {
                Group {
                    if let mainViewModel = diContainer.appState.mainViewModel,
                       let spaceCoordinator = diContainer.appState.spaceCoordinator {
                        AddMemoryContentView()
                            .frame(width: 1280, height: 720)
                            .environmentObject(diContainer.appState)
                            .environmentObject(mainViewModel)
                            .environmentObject(spaceCoordinator)
                            .environmentObject(diContainer.addMemoryMainViewModel)
                    } else {
                        Text("Loading...")
                            .frame(width: 1280, height: 720)
                    }
                }
            }
        }
        .windowResizability(.contentSize)

        // MemoryDetailView를 직접 사용하여 단일 파일로 관리합니다.
        WindowGroup(id: "Memory-Detail", for: Memory.self) { $memory in
            if let memory = memory {
                if let spaceCoordinator = diContainer.appState.spaceCoordinator {
                    MemoryDetailView(
                        memory: memory,
                        memoryRepository: diContainer.memoryRepository,
                        profileUseCase: diContainer.profileUseCase,
                        authRepository: diContainer.authRepository,
                        appState: diContainer.appState,
                        spaceCoordinator: spaceCoordinator
                    )
                    .frame(width: 1280, height: 720)
                    .environmentObject(diContainer.appState)
                    .environmentObject(spaceCoordinator)
                } else {
                    Text("Loading...")
                        .frame(width: 1280, height: 720)
                        .onAppear {
                            os.Logger().error("🔴 MemoryDetailView: spaceCoordinator is nil!")
                        }
                }
            } else {
                EmptyView()
            }
        }
        .windowResizability(.contentSize)
        
        WindowGroup(id: "Explore-Navigator", for: UUID.self) { $profileId in
            if let profileId = profileId {
                Group {
                    if let spaceCoordinator = diContainer.appState.spaceCoordinator {
                        ExploreNavigatorView(profileId: profileId)
                            .frame(width: 720, height: 188)
                            .environmentObject(diContainer.appState)
                            .environmentObject(spaceCoordinator)
                            .environmentObject(diContainer.exploreViewModel)
                    } else {
                        Text("Loading...")
                            .frame(width: 720, height: 188)
                    }
                }
            } else {
                Text("No user selected.")
                    .frame(width: 720, height: 188)
            }
        }
        .windowResizability(.contentSize)
    }
}
