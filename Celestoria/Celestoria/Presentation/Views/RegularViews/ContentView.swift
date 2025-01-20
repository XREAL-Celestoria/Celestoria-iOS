//
//  ContentView.swift
//  Celestoria
//
//  Created by Minjun Kim on 1/16/25.
//

import SwiftUI
import RealityKit
import RealityKitContent
import os

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
    @EnvironmentObject var loginViewModel: LoginViewModel
    @State private var activeScreen: ActiveScreen = .login
    
    var body: some View {
        Group {
            switch appModel.activeScreen {
            case .login:
                GradientBorderContainer {
                    LoginView()
                        .transition(.opacity)
                        .onAppear {
                            Logger.info("Displaying Login View")
                        }
                }
            case .main:
                GradientBorderContainer {
                    MainView()
                        .transition(.opacity)
                        .onAppear {
                            Logger.info("Displaying Main View")
                        }
                }
            case .galaxy:
                GradientBorderContainer {
                    GalaxyView()
                        .transition(.opacity)
                        .onAppear {
                            Logger.info("Displaying Galaxy View")
                        }
                }
            case .explore:
                GradientBorderContainer {
                    ExploreView()
                        .transition(.opacity)
                        .onAppear {
                            Logger.info("Displaying Explore View")
                        }
                }
            case .setting:
                GradientBorderContainer {
                    SettingView()
                        .transition(.opacity)
                        .onAppear {
                            Logger.info("Setting Login View")
                        }
                }
            case .addMemory:
                GradientBorderContainer {
                    MainView()
                        .transition(.opacity)
                        .onAppear {
                            Logger.info("Displaying Add memory View")
                        }
                }
            }
        }
    }
}

