//
//  AddMemoryDoneView.swift
//  Celestoria
//
//  Created by Park Seyoung on 1/22/25.
//

import SwiftUI

struct AddMemoryDoneView: View {
    @EnvironmentObject private var appModel: AppModel
    @EnvironmentObject var viewModel: AddMemoryMainViewModel
    @Environment(\.dismissWindow) private var dismissWindow
    
    var body: some View {
        VStack {
            NavigationBar(
                title: "Add Memory Star",
                action: {
                    dismissWindow(id: "Add-Memory")
                },
                buttonImageString: "xmark"
            )
            .padding(.horizontal, 28)
            .padding(.top, 28)
            
            Spacer()
            
            Image("AddMemoryDone")
                .resizable()
                .scaledToFit()
                .frame(width: 320, height: 320, alignment: .center)
            
            Spacer()
            
            Text("The memory star upload has been completed.")
                .foregroundColor(Color.NebulaWhite)
                .font(.system(size: 17, weight: .medium))
            
            Text("Why not take a moment to explore the memory star you created?")
                .foregroundColor(Color.NebulaWhite)
                .font(.system(size: 22, weight: .bold))
            
            Spacer()
            
            Button(action: {

                dismissWindow(id: "Add-Memory")
            }) {
                Text("View Memory Star")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(Color.NebulaBlack)
                    .frame(width: 380, height: 64)
                    .background(LinearGradient.GradientSub
                        .cornerRadius(16))
            }
            .buttonStyle(MainButtonStyle())
            .padding(.bottom, 96)
        }
        .onDisappear {
            viewModel.handleViewDisappearance()
            appModel.showAddMemoryView = false
            appModel.addMemoryScreen = .main
        }
    }
}

#Preview {
    AddMemoryDoneView()
}
