//
//  AddMemoryDoneView.swift
//  Celestoria
//
//  Created by Park Seyoung on 1/22/25.
//

import SwiftUI

struct AddMemoryDoneView: View {
    @EnvironmentObject private var appModel: AppModel
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
            
            Image("AddMemoryDone")
                .resizable()
                .scaledToFit()
                .frame(width: 248, height: 248, alignment: .center)
                .padding(.top, 64)
            
            Text("The memory star upload has been completed.")
                .foregroundColor(Color.NebulaWhite)
                .font(.system(size: 17, weight: .medium))
                .padding(.top, 32)
            
            Text("Why not take a moment to explore the memory star you created?")
                .foregroundColor(Color.NebulaWhite)
                .font(.system(size: 22, weight: .bold))
            
            Spacer()
            
            Button(action: {
               // 해당 별의 위치로 카메라 이동 
                
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
//            viewModel.handleViewDisappearance()
            appModel.showAddMemoryView = false
        }
    }
}

#Preview {
    AddMemoryDoneView()
}
