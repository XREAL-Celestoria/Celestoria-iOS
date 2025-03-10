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
    @EnvironmentObject var spaceCoordinator: SpaceCoordinator
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some View {
        VStack {
            HeaderView(title: "Celestoria", subtitle: "Spatial Video Social Network")
                .padding(.top, 108)
            
            Spacer()
                .frame(height: 40)
            
            AddMemoryButton {
                openAddMemoryView()
            }
            .frame(width: 288, height: 60)
            
            Spacer()
                .frame(height: 74)
            
            tabMenu
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .center)
        .background(Color.NebulaBlack.ignoresSafeArea())
        .overlay(loadingOverlay)
        .onAppear {
            // 메인 창 활성 상태 갱신
            appModel.mainWindowActive = true
            
            guard let userId = appModel.userId else { return }
            Task {
                // ImmersiveSpace 열기 로직은 동일
                if !appModel.isImmersiveViewActive {
                    await openImmersiveSpace(id: appModel.immersiveSpaceID)
                    appModel.isImmersiveViewActive = true
                }
                // userId 달라야만 loadData 호출
                if spaceCoordinator.currentLoadedUserId != userId {
                    await spaceCoordinator.loadData(for: userId)
                }
            }
        }
        .onDisappear {
            // 메인 창이 사라지면 상태 업데이트
            appModel.mainWindowActive = false
        }
        .onChange(of: scenePhase) { newPhase in
            switch newPhase {
            case .background, .inactive:
                os.Logger.info("App is moving to background/inactive. Closing Immersive Space.")
                appModel.isImmersiveViewActive = false
            case .active:
                os.Logger.info("App is active. Checking Immersive Space.")
                if appModel.userId != nil && !appModel.isImmersiveViewActive {
                    Task {
                        await openImmersiveSpace(id: appModel.immersiveSpaceID)
                        appModel.isImmersiveViewActive = true
                    }
                }
            default:
                break
            }
        }
    }
}

// MARK: - Subviews
private extension MainView {
    var tabMenu: some View {
        HStack(spacing: 70) {
            MainTabButton(imageName: "Galaxy", text: "Galaxy") {
                appModel.activeScreen = .galaxy
                os.Logger.info("Move to Galaxy View")
            }
            .frame(width: 104, height: 152)
            
            MainTabButton(imageName: "Explore", text: "Explore") {
                appModel.activeScreen = .explore
                os.Logger.info("Move to Explore View")
            }
            .frame(width: 104, height: 152)
            
            MainTabButton(imageName: "Setting", text: "Setting") {
                appModel.activeScreen = .setting
                os.Logger.info("Move to Setting View")
            }
            .frame(width: 104, height: 152)
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
    
    var loadingOverlay: some View {
        Group {
            if spaceCoordinator.isLoading {
                ZStack {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                    ProgressView("Loading Stars...")
                        .scaleEffect(1.5)
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .zIndex(1)
                }
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

