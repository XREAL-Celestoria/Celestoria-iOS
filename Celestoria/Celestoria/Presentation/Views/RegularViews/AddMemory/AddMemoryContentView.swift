//
//  AddMemoryContentView.swift
//  Celestoria
//
//  Created by Park Seyoung on 1/22/25.
//

import SwiftUI

struct AddMemoryContentView: View {
    @EnvironmentObject var appModel: AppModel
    

    var body: some View {
        Group {
            switch appModel.addMemoryScreen {
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
