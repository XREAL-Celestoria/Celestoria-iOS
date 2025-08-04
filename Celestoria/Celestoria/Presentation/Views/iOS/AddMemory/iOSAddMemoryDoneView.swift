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
    let onShowMemoryDetail: (Memory) -> Void
    let onComplete: () -> Void
    
    var body: some View {
        ZStack {
            // Background
            Colors.BackgroundBlack
                .ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                // Success Icon
                Image("AddMemoryDone")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 160, height: 160)
                    .scaleEffect(animateIcon ? 1 : 0.5)
                    .opacity(animateIcon ? 1 : 0)
                
                
                Spacer()
                
                // Success Message
                VStack(spacing: 16) {
                    Text("The Memory Star upload has been completed.")
                        .fontStyle(Fonts.callout)
                        .foregroundColor(Colors.NebulaWhite)
                        .multilineTextAlignment(.center)
                    
                    Text("Why not take a moment to\nexplore the memory you created?")
                        .fontStyle(Fonts.title2)
                        .foregroundColor(Colors.NebulaWhite)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal)
                
                Spacer()
                
                // View Memory Button
                Button(action: {
                    print("🔍 View Memory Star button tapped")
                    if let memory = viewModel.getLastUploadedMemory() {
                        print("✅ Memory found: \(memory.id.uuidString)")
                        print("🔍 Memory details:")
                        print("🔍   - Title: \(memory.title)")
                        print("🔍   - Note: \(memory.note)")
                        print("🔍   - Category: \(memory.category)")
                        print("🔍   - VideoURL: \(memory.videoURL ?? "nil")")
                        print("🔍   - ThumbnailURL: \(memory.thumbnailURL ?? "nil")")
                        print("🔍 Dismissing current view first")
                        
                        // 먼저 현재 뷰를 dismiss
                        dismiss()
                        
                        // AddMemory 뷰가 완전히 dismiss된 후에 MemoryDetail 표시 (지연 시간 증가)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            print("🔍 Calling onShowMemoryDetail callback after dismiss (1 second delay)")
                            onShowMemoryDetail(memory)
                        }
                    } else {
                        print("❌ No memory found from viewModel.getLastUploadedMemory()")
                        print("❌ Current lastUploadedMemory state: \(String(describing: viewModel.lastUploadedMemory))")
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
        .sheet(isPresented: $showMemoryDetail) {
            if let memory = viewModel.getLastUploadedMemory() {
                iOSMemoryDetailView(memory: memory, diContainer: diContainer)
            }
        }
        .onDisappear {
            viewModel.handleViewDisappearance()
            onComplete()
        }
    }
}
