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
                .environmentObject(diContainer.appModel)
                .environmentObject(diContainer.mainViewModel)
                .environmentObject(diContainer.loginViewModel)
        }
        
        ImmersiveSpace(id: diContainer.appModel.immersiveSpaceID) {
            SpaceImmersiveView()
                .environmentObject(diContainer.spaceCoordinator)
        }
        
        WindowGroup("Add Memory", id: "Add-Memory") {
            if diContainer.appModel.showAddMemoryView {
                AddMemoryContentView()
                    .environmentObject(diContainer.appModel)
                    .environmentObject(diContainer.addMemoryMainViewModel)
                    .environmentObject(diContainer.mainViewModel)
            }
        }
        
        // ** 새로 추가되는 부분: Memory를 인자로 받는 WindowGroup **
        WindowGroup(for: Memory.self) { $memory in
            /// - Swift 5.7~5.8 이후에는 `$memory.wrappedValue` 형태 사용.
            /// - `$memory`가 Binding<Memory?> 형태이므로 옵셔널 처리
            if let unwrappedMemory = $memory.wrappedValue {
                MemoryDetailView(memory: unwrappedMemory)
                    .environmentObject(diContainer.appModel)
            } else {
                // fallback UI
                Text("No memory provided.")
            }
        }

    }
}

