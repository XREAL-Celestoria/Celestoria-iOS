//
//  AppModel.swift
//  Celestoria
//
//  Created by Minjun Kim on 1/16/25.
//

// 전역 상태 관리, ImmersiveSpace 상태 정보 유지, 상태 변경(화면 전환, ImmersiveSpace 활성화) 관리

import Foundation
import os

@MainActor
final class AppModel: ObservableObject {
    @Published var userId: UUID = UUID() {
        didSet {
            os.Logger.info("User ID changed: \(userId)")
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
    
    let immersiveSpaceID = "SpaceEnvironment"
    
    init() {
        Logger.info("AppModel initialized with immersiveSpaceID: \(immersiveSpaceID)")
    }
}
