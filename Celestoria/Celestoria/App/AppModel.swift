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

    // ★ userProfile 추가: DB에서 가져온 값
    @Published var userProfile: UserProfile? {
        didSet {
            // userProfile가 업데이트될 때 starfield 동기화
            if let sfName = userProfile?.starfield,
               let starfieldEnum = StarField(imageName: sfName) {
                self.selectedStarfield = starfieldEnum
            } else {
                // ★ 로그인 안되거나 starfield가 없다면 Gray로 고정
                self.selectedStarfield = .GRAY
            }
        }
    }
    
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
    
    @Published var showExploreNavigatorView: Bool = false {
        didSet {
            Logger.info("showExploreNavigatorView : \(showExploreNavigatorView)")
        }
    }
    
    @Published var addMemoryScreen: AddMemoryScreen = .main {
        didSet {
            Logger.info("Add Memory - Active Screen changed: \(activeScreen)")
        }
    }
    
    let immersiveSpaceID = "SpaceEnvironment"
    
    init() {
        selectedStarfield = nil
        
        Logger.info("AppModel initialized with immersiveSpaceID: \(immersiveSpaceID)")
    }
}
