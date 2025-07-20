//
//  iPhoneContentView.swift
//  Celestoria
//
//  Created by Minjun Kim on 7/20/25.
//

import SwiftUI

// This file is kept for backward compatibility
// The actual iOS content view is now iOSContentView
struct iPhoneContentView: View {
    let diContainer: DIContainer
    
    init(diContainer: DIContainer) {
        self.diContainer = diContainer
    }
    
    var body: some View {
        iOSContentView(diContainer: diContainer)
    }
}
