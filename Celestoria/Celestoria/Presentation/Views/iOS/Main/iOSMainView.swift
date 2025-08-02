//
//  iOSMainView.swift
//  Celestoria
//
//  Created by Minjun Kim on 7/20/25.
//

import SwiftUI

struct iOSMainView: View {
    @EnvironmentObject var appState: AppState
    let diContainer: DIContainer
    
    init(diContainer: DIContainer) {
        self.diContainer = diContainer
    }
    
    var body: some View {
        NavigationView {
            iOS3DGalaxyContainerView(diContainer: diContainer)
                .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            if appState.galaxyTargetUserId == nil {
                appState.galaxyTargetUserId = appState.currentUserId
            }
        }
    }
}