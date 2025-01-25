//
//  AppModel.swift
//  Celestoria
//
//  Created by Minjun Kim on 1/16/25.
//

import Foundation
import os

@MainActor
final class AppModel: ObservableObject {
    
    @Published var randomBackground: String
    
    @Published var selectedStarfield: StarField? {
        didSet {
            if let starfield = selectedStarfield {
                Logger.info("Starfield Changed: \(starfield.rawValue)")
            } else {
                Logger.info("Starfield Changed: nil")
            }
        }
    }

    @Published var userId: UUID? = nil {
        didSet {
            os.Logger.info("User ID changed: \(String(describing: userId))")
        }
    }
    
    @Published var isImmersiveViewActive: Bool = false {
        didSet {
            Logger.info("Immersive View Active: \(isImmersiveViewActive)")
        }
    }
    
    @Published var activeScreen: ActiveScreen = .login {
        didSet {
            Logger.info("Active Screen changed: \(activeScreen)")
        }
    }
    
    @Published var showAddMemoryView: Bool = false {
        didSet {
            Logger.info("showAddMemoryView : \(showAddMemoryView)")
        }
    }
    
    @Published var addMemoryScreen: AddMemoryScreen = .main {
        didSet {
            Logger.info("Add Memory - Active Screen changed: \(activeScreen)")
        }
    }
    
    let immersiveSpaceID = "SpaceEnvironment"
    
    init() {
        let randomField = StarField.random()
        randomBackground = randomField.imageName
        selectedStarfield = nil
        Logger.info("AppModel initialized with random background: \(randomBackground)")
        Logger.info("AppModel initialized with immersiveSpaceID: \(immersiveSpaceID)")
    }
}
