//
//  Screen.swift
//  Celestoria
//
//  Created by Park Seyoung on 1/22/25.
//

import Foundation

enum AddMemoryScreen {
    case main
    case done
}

enum ActiveScreen {
    case login
    case main
    case galaxy
    case explore
    case setting
    case terms
}

enum NavigationState {
    case onboarding
    case login
    case terms
    case initializing  // 약관동의 후 앱 초기화 로딩
    case main
}
