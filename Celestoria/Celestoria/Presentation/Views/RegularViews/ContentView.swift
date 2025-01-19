//
//  ContentView.swift
//  Celestoria
//
//  Created by Minjun Kim on 1/16/25.
//

import SwiftUI
import RealityKit
import RealityKitContent

enum ActiveScreen {
    case main
    case addMemory //emotionSelection
}

struct ContentView: View {
    @EnvironmentObject var appModel: AppModel
    @EnvironmentObject var mainViewModel: MainViewModel
    @State private var activeScreen: ActiveScreen = .main

    var body: some View {
        Group {
            switch activeScreen {
            case .main:
                GradientBorderContainer {
                    MainView()
                }
            case .addMemory:
                GradientBorderContainer {
                    MainView()
                }
            }
        }
    }
}

