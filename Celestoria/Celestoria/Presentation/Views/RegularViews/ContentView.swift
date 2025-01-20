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
    case login
    case main
    case galaxy
    case explore
    case setting
    case addMemory
}

struct ContentView: View {
    @EnvironmentObject var appModel: AppModel
    @EnvironmentObject var mainViewModel: MainViewModel
    //
    @State private var activeScreen: ActiveScreen = .login

    var body: some View {
        Group {
            switch activeScreen {
            case .login:
                GradientBorderContainer {
                    LoginView()
                }
            case .main:
                GradientBorderContainer {
                    MainView()
                }
            case .galaxy:
                GradientBorderContainer {
                    GalaxyView()
                }
            case .explore:
                GradientBorderContainer {
                    ExploreView()
                }
            case .setting:
                GradientBorderContainer {
                    SettingView()
                }
            case .addMemory:
                GradientBorderContainer {
                    MainView()
                }
            }
        }
    }
}

