//
//  iOS3DGalaxyView.swift
//  Celestoria
//
//  Created by Minjun Kim on 7/20/25.
//


import SwiftUI
import SceneKit
import AudioToolbox
import os

struct iOS3DGalaxyView: View {
    @StateObject private var viewModel: iOS3DGalaxyViewModel
    
    init(galaxyViewModel: GalaxyViewModel, appState: AppState, diContainer: DIContainer) {
        _viewModel = StateObject(wrappedValue: iOS3DGalaxyViewModel(galaxyViewModel: galaxyViewModel, appState: appState, diContainer: diContainer))
    }
    
    var body: some View {
        ZStack {
            if viewModel.isContentReady {
                GalaxySceneView(viewModel: viewModel)
                    .edgesIgnoringSafeArea(.all)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            } else {
                // 로딩 중일 때는 빈 화면 (스플래시는 상위에서 처리)
                Color.black
                    .edgesIgnoringSafeArea(.all)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 1.5), value: viewModel.isContentReady)
        .fullScreenCover(isPresented: $viewModel.showMemoryDetail, onDismiss: {
            viewModel.clearSelectedMemory()
        }) {
            if let memory = viewModel.selectedMemory {
                iOSMemoryDetailView(memory: memory, diContainer: viewModel.diContainer)
            } else {
                Text("No memory selected")
                    .foregroundColor(.white)
                    .onAppear {
                        Logger.error("ERROR: showMemoryDetail is true but selectedMemory is nil!")
                    }
            }
        }
    }
}

struct GalaxySceneView: UIViewRepresentable {
    @ObservedObject var viewModel: iOS3DGalaxyViewModel
    
    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.backgroundColor = UIColor.black
        scnView.autoenablesDefaultLighting = false
        scnView.allowsCameraControl = true
        scnView.showsStatistics = false
        
        let scene = SCNScene()
        scnView.scene = scene
        
        viewModel.setupScene(scene)
        viewModel.loadMemories()
        
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        scnView.addGestureRecognizer(tapGesture)
        
        return scnView
    }
    
    func updateUIView(_ uiView: SCNView, context: Context) {
        viewModel.updateMemories()
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel)
    }
    
    class Coordinator: NSObject {
        private let viewModel: iOS3DGalaxyViewModel
        
        init(viewModel: iOS3DGalaxyViewModel) {
            self.viewModel = viewModel
        }
        
        @MainActor @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let scnView = gesture.view as? SCNView else { return }
            
            let location = gesture.location(in: scnView)
            let hitResults = scnView.hitTest(location, options: [:])
            
            Logger.debug("=== TAP DEBUG ===")
            Logger.debug("Tap detected at: \(location)")
            Logger.debug("Hit results count: \(hitResults.count)")
            Logger.debug("Total memory nodes: \(viewModel.memoryNodes.count)")
            
            if let result = hitResults.first {
                Logger.debug("Hit node: \(result.node)")
                Logger.debug("Hit node name: \(result.node.name ?? "no name")")
                
                // Check if the hit node is a child of iOS3DMemoryStarNode
                var checkNode: SCNNode? = result.node
                var depth = 0
                while checkNode != nil {
                    Logger.debug("Checking node at depth \(depth): \(checkNode?.description ?? "nil")")
                    if let memoryNode = checkNode as? iOS3DMemoryStarNode {
                        AudioServicesPlaySystemSound(1104)
                        Logger.debug("Memory data before selection:")
                        Logger.debug("  - ID: \(memoryNode.memory.id)")
                        Logger.debug("  - Title: \(memoryNode.memory.title)")
                        Logger.debug("  - Note: \(memoryNode.memory.note)")
                        Logger.debug("  - Category: \(memoryNode.memory.category)")
                        Logger.debug("  - VideoURL: \(memoryNode.memory.videoURL ?? "nil")")
                        Logger.debug("  - ThumbnailURL: \(memoryNode.memory.thumbnailURL ?? "nil")")
                        
                        viewModel.handleMemorySelection(memoryNode.memory)
                        return
                    }
                    checkNode = checkNode?.parent
                    depth += 1
                }
                Logger.debug("No memory node found in hierarchy after checking \(depth) levels")
            } else {
                Logger.debug("No hit results")
            }
            Logger.debug("=== END TAP DEBUG ===")
        }
    }
}


// 네비게이션 관리 
struct iOS3DGalaxyContainerView: View {
    let diContainer: DIContainer
    @EnvironmentObject var appState: AppState
    @StateObject private var galaxyViewModel: GalaxyViewModel
    @State private var activeScreen: MainActiveScreen?
    @State private var containerOpacity: Double = 0
    @State private var settingsNavigationPath: [SettingsScreen] = []
    
    enum MainActiveScreen {
        case explore, notification, addMemory, settings, memoryDetail(Memory)
    }
    
    enum SettingsScreen: Hashable {
        case galaxy, profile, thumbnail, account, blockedUsers
    }
    
    init(diContainer: DIContainer) {
        self.diContainer = diContainer
        _galaxyViewModel = StateObject(wrappedValue: diContainer.makeGalaxyViewModel())
    }
    
    var body: some View {
        iOS3DGalaxyView(
            galaxyViewModel: galaxyViewModel,
            appState: appState,
            diContainer: diContainer
        )
        .opacity(containerOpacity)
        .animation(.easeInOut(duration: 1.0), value: containerOpacity)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0).delay(0.3)) {
                containerOpacity = 1
            }
        }
        .fullScreenCover(isPresented: Binding(
            get: { activeScreen != nil },
            set: { if !$0 { activeScreen = nil } }
        )) {
            if let screen = activeScreen {
                switch screen {
                case .explore:
                    ExploreView()
                        .customNavigationView(title: "Explore", onBack: { activeScreen = nil })
                case .notification:
                    NotificationView()
                case .addMemory:
                    iOSAddMemoryContentView(diContainer: diContainer)
                        .customNavigationView(title: "Add Memory", onBack: { activeScreen = nil })
                case .settings:
                    NavigationStack(path: $settingsNavigationPath) {
                        iOSSettingsView(
                            diContainer: diContainer, 
                            navigationPath: $settingsNavigationPath,
                            onBack: { activeScreen = nil }
                        )
                            .navigationDestination(for: SettingsScreen.self) { screen in
                                switch screen {
                                case .galaxy:
                                    iOSGalaxySettingView(diContainer: diContainer)
                                case .profile:
                                    iOSProfileSettingView(diContainer: diContainer)
                                case .thumbnail:
                                    iOSThumbnailSettingView(diContainer: diContainer)
                                case .account:
                                    iOSAccountSettingView(diContainer: diContainer)
                                case .blockedUsers:
                                    iOSBlockedUsersSettingView(diContainer: diContainer)
                                }
                            }
                    }
                    .navigationViewStyle(StackNavigationViewStyle())
                case .memoryDetail(let memory):
                    iOSMemoryDetailView(memory: memory, diContainer: diContainer)
                }
            }
        }
        .onChange(of: appState.refreshMainView) { _, shouldRefresh in
            if shouldRefresh {
                galaxyViewModel.refreshGalaxy()
                // 다른 옵저버들이 처리할 시간을 주기 위해 약간의 지연 추가
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    appState.refreshMainView = false
                }
            }
        }
        .onReceive(appState.$selectedMemoryForDetail) { memory in
            if let memory = memory {
                activeScreen = .memoryDetail(memory)
            }
        }
        .overlay(
            // 상단 버튼들 - 독립적인 ZStack
            VStack {
                HStack {
                    Spacer()
                    
                    HStack(spacing: 16) {
                        Button(action: { activeScreen = .explore }) {
                            Image("exploreIcon")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)
                        }
                        
                        Button(action: { activeScreen = .notification }) {
                            Image("NotificationIcon")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)
                        }
                        
                        Button(action: { activeScreen = .settings }) {
                            Image("menuIcon")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)
                        }
                    }
                    .padding(.trailing, 16)
                    .padding(.top, 16)
                }
                
                Spacer()
            }
        )
        .overlay(
            // 하단 유저 모달 - 독립적인 ZStack
            VStack {
                Spacer()
                    .frame(minHeight: 52)
                
                if let targetUserId = appState.galaxyTargetUserId {
                    UserInfoModalView(
                        userId: targetUserId,
                        isOwnGalaxy: targetUserId == appState.currentUserId,
                        onAddMemory: {
                            appState.showAddMemoryView = true
                        },
                        diContainer: diContainer
                    )
                }
            }
        )
    }
}

// 화면들
struct ExploreView: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack {
                Text("Explore")
                    .font(.largeTitle)
                    .foregroundColor(.white)
                Text("탐색 화면")
                    .foregroundColor(.gray)
            }
        }
    }
}

struct NotificationView: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack {
                Text("Notification")
                    .font(.largeTitle)
                    .foregroundColor(.white)
                Text("알림 화면")
                    .foregroundColor(.gray)
            }
        }
    }
}
