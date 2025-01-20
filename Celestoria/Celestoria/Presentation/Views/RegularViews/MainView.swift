//
//  MainView.swift
//  Celestoria
//
//  Created by Park Seyoung on 1/20/25.
//

import SwiftUI

struct MainView: View {
    @EnvironmentObject var viewModel: MainViewModel
    @EnvironmentObject var appModel: AppModel
    @State private var activeScreen: ActiveScreen = .main
    
    var body: some View {
        GeometryReader { geometry in
            
            VStack {
                HeaderView(title: "Celestoria", subtitle: "Spatial Video Social Network")
                    .padding(.top, geometry.size.height * 0.2)
                Spacer()
                    .frame(height: geometry.size.height * 0.05)
                AddMemoryButton {
                    activeScreen = .addMemory
                }
                .frame(width: geometry.size.width * 0.28, height: geometry.size.height * 0.08 ,alignment: .center)
                
                Spacer()
                    .frame(height: geometry.size.height * 0.1)
                
                tabMenu
                    .padding(.bottom, geometry.size.height * 0.15)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            
            if viewModel.isLoading {
                loadingView
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            
            if let errorMessage = viewModel.errorMessage {
                ErrorBannerView(message: errorMessage) {
                    viewModel.errorMessage = nil
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 16)
                .padding(.top, geometry.safeAreaInsets.top + 10)
                .zIndex(1)
            }
        }
        .onAppear {
            viewModel.fetchMemories(for: appModel.userId)
        }
    }
}

// MARK: - Subviews
private extension MainView {
    var tabMenu: some View {
        GeometryReader { geometry in
            HStack(spacing: geometry.size.width * 0.05) {
                MainTabButton(imageName: "GalaxyTabButton", text: "Galaxy") {
                    print("Galaxy Button Tapped")
                }
                .frame(width: geometry.size.width * 0.08, height: geometry.size.height * 0.2)
                
                MainTabButton(imageName: "ExploreTabButton", text: "Explore") {
                    print("Explore Button Tapped")
                }
                .frame(width: geometry.size.width * 0.08, height: geometry.size.height * 0.2)
                
                MainTabButton(imageName: "SettingTabButton", text: "Setting") {
                    print("Setting Button Tapped")
                }
                .frame(width: geometry.size.width * 0.08, height: geometry.size.height * 0.2)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.bottom, geometry.size.height * 0.05)
        }
    }
    
    var loadingView: some View {
        ProgressView()
            .scaleEffect(1.5)
            .progressViewStyle(CircularProgressViewStyle(tint: .white))
    }
}
