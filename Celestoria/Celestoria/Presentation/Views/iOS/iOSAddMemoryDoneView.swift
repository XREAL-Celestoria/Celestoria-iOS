//
//  iOSAddMemoryDoneView.swift
//  Celestoria
//
//  Created by Minjun Kim on 7/20/25.
//


import SwiftUI

struct iOSAddMemoryDoneView: View {
    @ObservedObject var viewModel: AddMemoryMainViewModel
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var showMemoryDetail = false
    let diContainer: DIContainer
    
    var body: some View {
        ZStack {
            // Background
            Color.NebulaBlack
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Spacer()
                
                // Success Icon
                ZStack {
                    Image(systemName: "star.circle.fill")
                        .font(.system(size: 100))
                        .foregroundStyle(LinearGradient.GradientMain)
                    Image(systemName: "checkmark")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.NebulaBlack)
                }
                .padding(.bottom, 20)
                
                // Success Message
                VStack(spacing: 16) {
                    Text("The memory star upload has been completed.")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text("Why not take a moment to explore the memory star you created?")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                
                Spacer()
                
                // View Memory Button
                Button(action: {
                    if let memory = viewModel.getLastUploadedMemory() {
                        showMemoryDetail = true
                    }
                }) {
                    HStack {
                        Image(systemName: "star.fill")
                            .font(.system(size: 20))
                        Text("View Memory Star")
                            .font(.system(size: 20, weight: .semibold))
                    }
                    .foregroundColor(.NebulaBlack)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(LinearGradient.GradientSub)
                    .cornerRadius(16)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("Add Memory Star")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    // Dismiss entire navigation stack
                    dismiss()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                }
            }
        }
        .sheet(isPresented: $showMemoryDetail) {
            if let memory = viewModel.getLastUploadedMemory() {
                iOSMemoryDetailView(memory: memory, diContainer: diContainer)
            }
        }
        .onDisappear {
            viewModel.handleViewDisappearance()
        }
    }
}