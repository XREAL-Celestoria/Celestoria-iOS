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
    
    init(galaxyViewModel: GalaxyViewModel, appState: AppState, diContainer: DIContainer, onMemorySelected: @escaping (Memory) -> Void) {
        _viewModel = StateObject(wrappedValue: iOS3DGalaxyViewModel(galaxyViewModel: galaxyViewModel, appState: appState, diContainer: diContainer))
        
        // 콜백 설정은 onAppear에서 처리 (StateObject 초기화 후)
        self.onMemorySelectedCallback = onMemorySelected
    }
    
    private let onMemorySelectedCallback: (Memory) -> Void
    
    var body: some View {
        ZStack {
            // Scene은 항상 렌더링하되, opacity로 표시 여부 제어
            GalaxySceneView(viewModel: viewModel)
                .edgesIgnoringSafeArea(.all)
                .opacity(viewModel.isContentReady ? 1.0 : 0.0)
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            
            // 로딩 중일 때 검은 화면 오버레이
            if !viewModel.isContentReady {
                Color.black
                    .edgesIgnoringSafeArea(.all)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 1.5), value: viewModel.isContentReady)
        .onAppear {
            // 콜백 설정
            viewModel.onMemorySelected = onMemorySelectedCallback
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
            
            print("🔍 === TAP DEBUG ===")
            print("🔍 Tap detected at: \(location)")
            print("🔍 Hit results count: \(hitResults.count)")
            print("🔍 Total memory nodes: \(viewModel.memoryNodes.count)")
            
            if let result = hitResults.first {
                print("🔍 Hit node: \(result.node)")
                print("🔍 Hit node name: \(result.node.name ?? "no name")")
                
                // Check if the hit node is a child of iOS3DMemoryStarNode
                var checkNode: SCNNode? = result.node
                var depth = 0
                while checkNode != nil {
                    print("🔍 Checking node at depth \(depth): \(checkNode?.description ?? "nil")")
                    if let memoryNode = checkNode as? iOS3DMemoryStarNode {
                        AudioServicesPlaySystemSound(1104)
                        print("🔍 Memory data before selection:")
                        print("🔍   - ID: \(memoryNode.memory.id)")
                        print("🔍   - Title: \(memoryNode.memory.title)")
                        print("🔍   - Note: \(memoryNode.memory.note)")
                        print("🔍   - Category: \(memoryNode.memory.category)")
                        print("🔍   - VideoURL: \(memoryNode.memory.videoURL ?? "nil")")
                        print("🔍   - ThumbnailURL: \(memoryNode.memory.thumbnailURL ?? "nil")")
                        
                        viewModel.handleMemorySelection(memoryNode.memory)
                        return
                    }
                    checkNode = checkNode?.parent
                    depth += 1
                }
                print("🔍 No memory node found in hierarchy after checking \(depth) levels")
            } else {
                print("🔍 No hit results")
            }
            print("🔍 === END TAP DEBUG ===")
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
    @State private var lastTargetUserId: UUID? // UserInfoModal 안정화를 위해
    @State private var shouldShowUserModal: Bool = false // 모달 표시 제어
    @State private var modalRefreshCounter = 0 // UserInfoModal 강제 리프레시용
    
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
            diContainer: diContainer,
            onMemorySelected: { memory in
                print("🔍 iOS3DGalaxyContainerView - Memory selected from 3D view: \(memory.id.uuidString)")
                activeScreen = .memoryDetail(memory)
            }
        )
        .opacity(containerOpacity)
        .animation(.easeInOut(duration: 1.0), value: containerOpacity)
        .onAppear {
            print("🔍 iOS3DGalaxyContainerView - onAppear")
            withAnimation(.easeInOut(duration: 1.0).delay(0.3)) {
                containerOpacity = 1
            }
            
            // 초기 UserInfoModal 상태 설정 (안정화)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if let targetUserId = appState.galaxyTargetUserId {
                    shouldShowUserModal = true
                    lastTargetUserId = targetUserId
                }
            }
        }
        .onDisappear {
            print("🔍 iOS3DGalaxyContainerView - onDisappear")
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
                    iOSAddMemoryContentView(
                        diContainer: diContainer,
                        onShowMemoryDetail: { memory in
                            print("🔍 iOS3DGalaxyContainerView - Callback received from AddMemory")
                            print("🔍 Memory ID: \(memory.id.uuidString)")
                            print("🔍 Current activeScreen: \(String(describing: activeScreen))")
                            print("🔍 Setting activeScreen to memoryDetail")
                            
                            DispatchQueue.main.async {
                                activeScreen = .memoryDetail(memory)
                                print("🔍 ActiveScreen successfully set to memoryDetail(\(memory.id.uuidString))")
                            }
                        }
                    )
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
                        .onAppear {
                            print("🔍 iOSMemoryDetailView appeared for memory: \(memory.id.uuidString)")
                        }
                        .onDisappear {
                            print("🔍 iOSMemoryDetailView disappeared for memory: \(memory.id.uuidString)")
                        }
                }
            }
        }
        .onChange(of: appState.refreshMainView) { _, shouldRefresh in
            if shouldRefresh {
                print("ℹ️ INFO: Refresh Main View: \(shouldRefresh)")
                galaxyViewModel.refreshGalaxy()
                // UserInfoModal 강제 리프레시
                modalRefreshCounter += 1
                print("ℹ️ INFO: UserInfoModal refresh counter: \(modalRefreshCounter)")
                // 즉시 false로 설정하여 중복 리프레시 방지
                appState.refreshMainView = false
            }
        }
        .onChange(of: appState.galaxyTargetUserId) { _, newTargetUserId in
            // UserInfoModal 표시 조건 최적화
            if let newUserId = newTargetUserId, newUserId != lastTargetUserId {
                shouldShowUserModal = true
                lastTargetUserId = newUserId
            } else if newTargetUserId == nil {
                shouldShowUserModal = false
                lastTargetUserId = nil
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
            // 하단 유저 모달 - 최적화된 조건부 렌더링
            VStack {
                Spacer()
                    .frame(minHeight: 52)
                
                if let targetUserId = appState.galaxyTargetUserId,
                   shouldShowUserModal {
                    UserInfoModalView(
                        userId: targetUserId,
                        isOwnGalaxy: targetUserId == appState.currentUserId,
                        onAddMemory: {
                            activeScreen = .addMemory
                        },
                        diContainer: diContainer
                    )
                    .id("UserInfoModal-\(targetUserId.uuidString)-\(modalRefreshCounter)")
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        )
        .animation(.easeInOut(duration: 0.3), value: shouldShowUserModal)
        .animation(.easeInOut(duration: 0.3), value: modalRefreshCounter)
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
