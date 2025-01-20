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
                header
                    .padding(.top, geometry.size.height * 0.2)
                Spacer()
                    .frame(height: geometry.size.height * 0.05)
                AddMemoryButton {
                    activeScreen = .addMemory
                }
                .frame(maxWidth: .infinity, alignment: .center)
                
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
    var header: some View {
        VStack(spacing: 10) {
            Text("Celestoria")
                .font(.system(size: 96, weight: .bold, design: .default))
                .foregroundStyle(LinearGradient.GradientMain)
                .multilineTextAlignment(.center)
            
            Text("SpatialVideo Social Network")
                .font(.system(size: 29, weight: .bold, design: .default))
                .foregroundStyle(LinearGradient.GradientMain)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.top, 20)
    }
    
    var tabMenu: some View {
        GeometryReader { geometry in
            HStack(spacing: geometry.size.width * 0.1) {
                MainButton(imageName: "GalaxyTabButton", text: "Galaxy") {
                    print("Galaxy Button Tapped")
                }
                .frame(width: geometry.size.width * 0.08, height: geometry.size.height * 0.2)
                
                MainButton(imageName: "ExploreTabButton", text: "Explore") {
                    print("Explore Button Tapped")
                }
                .frame(width: geometry.size.width * 0.08, height: geometry.size.height * 0.2)
                
                MainButton(imageName: "SettingTabButton", text: "Setting") {
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
    
    private var errorOverlay: some View {
        Group {
            if let errorMessage = viewModel.errorMessage {
                ErrorBannerView(message: errorMessage) {
                    viewModel.errorMessage = nil // 닫기 버튼 동작
                }
                .padding(.top, 10)
            } else {
                EmptyView()
            }
        }
    }
    
}
