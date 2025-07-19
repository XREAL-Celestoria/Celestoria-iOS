//
//  AddMemoryContentView.swift
//  Celestoria
//
//  Created by Park Seyoung on 1/22/25.
//

import SwiftUI

struct AddMemoryContentView: View {
    @EnvironmentObject var appState: AppState
    

    var body: some View {
        Group {
            switch appState.addMemoryScreen {
            case .main:
                GradientBorderContainer {
                    AddMemoryMainView()
                }
            case .done:
                GradientBorderContainer {
                    AddMemoryDoneView()
                }
            }
        }
    }
}
