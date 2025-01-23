//
//  MainView.swift
//  Celestoria
//
//  Created by Park Seyoung on 1/20/25.
//

import SwiftUI
import os

struct MainView: View {
    @EnvironmentObject var viewModel: MainViewModel
    @EnvironmentObject var appModel: AppModel
    @Environment(\.openWindow) private var openWindow
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    
    var body: some View {
        VStack {
            HeaderView(title: "Celestoria", subtitle: "Spatial Video Social Network")
                .padding(.top, 148)
            
            Spacer()
                .frame(height: 40)
            
            AddMemoryButton {
                openAddMemoryView()
            }
            .frame(width: 288, height: 60)
            
            Spacer()
                .frame(height: 84)
            
            tabMenu
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .center)
        .background(Color.NebulaBlack.ignoresSafeArea())
        .overlay(loadingOverlay)
        .onAppear {
            guard let userId = appModel.userId else { return }
            Task {
                await openImmersiveSpace(id: appModel.immersiveSpaceID)
                appModel.isImmersiveViewActive = true
                await viewModel.fetchMemories(for: userId)
            }
        }
    }
}

// MARK: - Subviews
private extension MainView {
    var tabMenu: some View {
        HStack(spacing: 40) {
            MainTabButton(imageName: "Nebula", text: "Galaxy") {
                print("Galaxy Button Tapped")
            }
            .frame(width: 104, height: 152)
            
            MainTabButton(imageName: "Explore", text: "Explore") {
                print("Explore Button Tapped")
            }
            .frame(width: 104, height: 152)
            
            MainTabButton(imageName: "Setting", text: "Setting") {
                print("Setting Button Tapped")
            }
            .frame(width: 104, height: 152)
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
    
    var loadingOverlay: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(1.5)
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .zIndex(1)
            }
            
            if let errorMessage = viewModel.errorMessage {
                ErrorBannerView(message: errorMessage) {
                    viewModel.errorMessage = nil
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .zIndex(1)
            }
        }
    }
}

// MARK: - Actions
private extension MainView {
    func openAddMemoryView() {
        guard !appModel.showAddMemoryView else {
            os.Logger.info("Add memory view already opened")
            return
        }
        
        os.Logger.info("Displaying Add memory View")
        appModel.showAddMemoryView = true
        openWindow(id: "Add-Memory")
    }
}

