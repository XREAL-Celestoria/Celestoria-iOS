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
    @State private var animateIcon = false
    @State private var showGlow = false
    let diContainer: DIContainer
    
    var body: some View {
        ZStack {
            // Background
            Color.black
                .ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                // Success Icon - using custom image if available, fallback to star
                if UIImage(named: "AddMemoryDone") != nil {
                    Image("AddMemoryDone")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 160, height: 160)
                        .scaleEffect(animateIcon ? 1 : 0.5)
                        .opacity(animateIcon ? 1 : 0)
                } else {
                    // Fallback design with star
                    ZStack {
                        // Glow effect
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [Color(hex: "#7B61FF").opacity(0.4), Color.clear],
                                    center: .center,
                                    startRadius: 10,
                                    endRadius: 80
                                )
                            )
                            .frame(width: 200, height: 200)
                            .blur(radius: 15)
                            .scaleEffect(showGlow ? 1.2 : 0.8)
                            .opacity(showGlow ? 1 : 0)
                        
                        // Star icon with gradient background
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: "#A68CFF"), Color(hex: "#7B61FF")],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 140, height: 140)
                            
                            Image(systemName: "star.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.white)
                        }
                        .scaleEffect(animateIcon ? 1 : 0.5)
                        .opacity(animateIcon ? 1 : 0)
                    }
                }
                
                Spacer()
                
                // Success Message
                VStack(spacing: 16) {
                    Text("The Memory Star upload has been completed.")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                    
                    Text("Why not take a moment to explore the memory you created?")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 32)
                
                Spacer()
                Spacer()
                
                // View Memory Button
                Button(action: {
                    if viewModel.getLastUploadedMemory() != nil {
                        showMemoryDetail = true
                    }
                }) {
                    Text("View Memory Star")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(Colors.NebulaBlack)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(LinearGradient.GradientSub)
                        )
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 50)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                animateIcon = true
            }
            withAnimation(.easeInOut(duration: 1).delay(0.3)) {
                showGlow = true
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
