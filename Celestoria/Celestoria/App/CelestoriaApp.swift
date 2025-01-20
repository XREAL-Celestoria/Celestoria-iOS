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
    }
}

