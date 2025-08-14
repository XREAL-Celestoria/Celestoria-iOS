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
import Foundation

struct iOS3DGalaxyView: View {
    @StateObject private var viewModel: iOS3DGalaxyViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedMemory: Memory?
    @State private var shouldCreateSceneView: Bool = true
    
    // 다른 유저의 우주를 보기 위한 생성자
    init(diContainer: DIContainer, targetUserId: UUID) {
        let galaxyViewModel = diContainer.makeGalaxyViewModel()
        let appState = AppState()
        
        // 현재 로그인된 사용자 ID 설정 (DIContainer에서 가져오기)
        if let currentUserId = diContainer.appState.userId {
            appState.userId = currentUserId
        }
        appState.galaxyTargetUserId = targetUserId
        
        _viewModel = StateObject(wrappedValue: iOS3DGalaxyViewModel(galaxyViewModel: galaxyViewModel, appState: appState, diContainer: diContainer))
        self.onMemorySelectedCallback = { _ in }
    }
    
    // 기존 생성자 (기존 코드와의 호환성을 위해)
    init(galaxyViewModel: GalaxyViewModel, appState: AppState, diContainer: DIContainer, onMemorySelected: @escaping (Memory) -> Void) {
        _viewModel = StateObject(wrappedValue: iOS3DGalaxyViewModel(galaxyViewModel: galaxyViewModel, appState: appState, diContainer: diContainer))
        
        // 콜백 설정은 onAppear에서 처리 (StateObject 초기화 후)
        self.onMemorySelectedCallback = onMemorySelected
    }
    
    private let onMemorySelectedCallback: (Memory) -> Void
    
    var body: some View {
        ZStack {
            // 무거운 SCNView 생성은 첫 프레임 이후로 미뤄서 오버레이가 즉시 보이도록 함
            if shouldCreateSceneView {
                GalaxySceneView(viewModel: viewModel)
                    .edgesIgnoringSafeArea(.all)
                    .opacity(viewModel.isContentReady ? 1.0 : 0.0) // 완전 불투명으로 변경
                    .animation(.easeInOut(duration: 0.3), value: viewModel.isContentReady) // 애니메이션 단축
            }
            
            // 로딩 오버레이를 항상 렌더링하고, 상태에 따라 투명도만 조절하여 첫 프레임부터 표시되도록 함
            iOSUnifiedLoadingView.fullscreen(title: viewModel.isOtherUserSpace ? "Loading Other Galaxy." : "Loading Galaxy.")
                .edgesIgnoringSafeArea(.all)
                .opacity((!viewModel.isContentReady || viewModel.isLoadingOtherUserGalaxy) ? 1.0 : 0.0)
                .animation(.easeInOut(duration: 0.25), value: viewModel.isContentReady)
                .animation(.easeInOut(duration: 0.25), value: viewModel.isLoadingOtherUserGalaxy)
                .zIndex(50) // 상단 버튼보다 낮게 설정
                .allowsHitTesting(false) // 로딩 오버레이가 터치를 차단하지 않도록
            
            // 내부 콘텐츠는 끝. 버튼/모달은 고정 오버레이로 분리합니다.
        }

        .onChange(of: viewModel.isContentReady) { _, isReady in
            if isReady {
                // 로딩이 완료되면 appState 업데이트
                DispatchQueue.main.async {
                    viewModel.appState.isGalaxyLoadingComplete = true
                }
            }
        }
        // Top-back button overlay (fixed position, above modal)
        .overlay(alignment: .topLeading) {
            if viewModel.isOtherUserSpace {
                Button(action: {
                    viewModel.dismissOtherUserSpace()
                    dismiss()
                }) {
                    Image("backButton")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .foregroundStyle(Colors.NebulaWhite)
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .zIndex(2)
            }
        }
        // Bottom user modal overlay (fixed, below back button)
        .overlay {
            VStack {
                    Spacer()
                        .frame(minHeight: 52)
                if viewModel.isContentReady && viewModel.isOtherUserSpace,
                   let targetUserId = viewModel.appState.galaxyTargetUserId {
                    UserInfoModalView(
                        userId: targetUserId,
                        isOwnGalaxy: (viewModel.appState.userId == targetUserId),
                        onAddMemory: nil,
                        onSelectMemory: { memory in
                            selectedMemory = memory
                        },
                        diContainer: viewModel.diContainer
                    )
                    .environmentObject(viewModel.appState)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(1)
                }
            }
        }
        .onAppear {
            // SCNView는 이미 true로 설정되어 있어서 즉시 생성됨
            // 콜백 설정 - 앱 스테이트를 사용하도록 수정
            viewModel.onMemorySelected = { memory in
                print("🔍 iOS3DGalaxyView - Memory selected from 3D view: \(memory.id.uuidString)")
                
                // 로컬 상태로 메모리 디테일 표시 (item 기반 프레젠테이션)
                selectedMemory = memory
                
                // 기존 콜백도 호출 (호환성을 위해)
                onMemorySelectedCallback(memory)
            }
        }
        .fullScreenCover(item: $selectedMemory) { memory in
            iOSMemoryDetailView(
                memory: memory,
                diContainer: viewModel.diContainer,
                onBack: {
                    selectedMemory = nil
                }
            )
            .environmentObject(viewModel.appState)
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
        
        // 로딩 상태를 즉시 표시하기 위해 초기화 시작
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
    @State private var containerOpacity: Double = 1
    @State private var settingsNavigationPath: [SettingsScreen] = []
    @State private var lastTargetUserId: UUID? // UserInfoModal 안정화를 위해
    @State private var shouldShowUserModal: Bool = false // 모달 표시 제어
    @State private var modalRefreshCounter = 0 // UserInfoModal 강제 리프레시용

    @State private var showingExploreSearch: Bool = false // Explore 검색 상태
    
    enum MainActiveScreen {
        case explore, notification, addMemory, settings
    }
    
    enum SettingsScreen: Hashable {
        case galaxy, profile, thumbnail, account, blockedUsers
    }
    
    init(diContainer: DIContainer) {
        self.diContainer = diContainer
        _galaxyViewModel = StateObject(wrappedValue: diContainer.makeGalaxyViewModel())
    }
    
    var body: some View {
        ZStack {
            // 갤럭시 뷰 (배경)
            iOS3DGalaxyView(
                galaxyViewModel: galaxyViewModel,
                appState: appState,
                diContainer: diContainer,
                onMemorySelected: { memory in
                    print("🔍 iOS3DGalaxyContainerView - Memory selected from 3D view: \(memory.id.uuidString)")
                }
            )
            .environmentObject(appState)
            .opacity(containerOpacity)
            
            // 상단 버튼들을 갤럭시 뷰와 완전히 분리된 절대 고정 위치로 배치
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
            .frame(maxWidth: .infinity, maxHeight: .infinity) // 전체 화면 고정
            .allowsHitTesting(true) // 터치 허용
            .zIndex(1000) // 최상위 레이어
            .opacity(appState.isGalaxyLoadingComplete ? 1.0 : 0.0) // 로딩 완료 시에만 표시
            .animation(.easeInOut(duration: 0.3), value: appState.isGalaxyLoadingComplete) // 부드러운 페이드인
        }
        .onAppear {
            print("🔍 iOS3DGalaxyContainerView - onAppear")
            // containerOpacity는 이미 1로 시작하므로 애니메이션 불필요
            
            // 초기 UserInfoModal 상태 설정 (로딩 완료 후에만 표시)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { // 1초로 늘림
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
                    NavigationStack {
                        iOSExploreView(
                            diContainer: diContainer,
                            showingSearchView: $showingExploreSearch
                        )
                        .customNavigationBarWithSearch(
                            title: "Explore",
                            onBack: { activeScreen = nil },
                            onSearch: { showingExploreSearch = true }
                        )
                    }
                    .navigationViewStyle(StackNavigationViewStyle())
                case .notification:
                    iOSNotificationView(diContainer: diContainer)
                        .customNavigationView(title: "Notice", onBack: { activeScreen = nil })
                case .addMemory:
                    iOSAddMemoryContentView(
                        diContainer: diContainer,
                        onShowMemoryDetail: { memory in
                            print("🔍 iOS3DGalaxyContainerView - Callback received from AddMemory")
                            print("🔍 Memory ID: \(memory.id.uuidString)")
                            print("🔍 Using app state for memory detail navigation")
                            
                            // 앱 스테이트를 통해 메모리 디테일 네비게이션
                            appState.selectedMemoryForDetail = memory
                            appState.shouldNavigateToMemoryDetail = true
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
                }
            }
        }
        .onChange(of: appState.refreshMainView) { _, shouldRefresh in
            if shouldRefresh {
                print("ℹ️ INFO: Refresh Main View: \(shouldRefresh)")
                
                // 현재 사용자의 유저모달만 업데이트 (다른 사람용은 제외)
                if let targetUserId = appState.galaxyTargetUserId,
                   targetUserId == appState.currentUserId {
                    // UserInfoModal을 부드럽게 숨기고 새로고침
                    withAnimation(.easeInOut(duration: 0.2)) {
                        shouldShowUserModal = false
                    }
                    
                    // 약간의 지연 후 UserInfoModal 다시 표시
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            shouldShowUserModal = true
                        }
                    }
                }
                
                // 갤럭시 새로고침
                galaxyViewModel.refreshGalaxy()
                
                // UserInfoModal 강제 리프레시 (현재 사용자용만)
                modalRefreshCounter += 1
                print("ℹ️ INFO: UserInfoModal refresh counter: \(modalRefreshCounter)")
                
                // 즉시 false로 설정하여 중복 리프레시 방지
                appState.refreshMainView = false
            }
        }
        .onChange(of: appState.galaxyTargetUserId) { _, newTargetUserId in
            // UserInfoModal 표시 조건 최적화 (로딩 완료 후에만 표시)
            if let newUserId = newTargetUserId, 
               newUserId != lastTargetUserId,
               appState.isGalaxyLoadingComplete, // 로딩 완료 상태 확인
               (newUserId == appState.currentUserId || // 현재 사용자이거나
                (newUserId != appState.currentUserId && appState.galaxyTargetUserId == newUserId)) { // 다른 사용자이고 실제로 해당 갤럭시를 보고 있는 경우
                lastTargetUserId = newUserId
                shouldShowUserModal = true
            } else if newTargetUserId == nil {
                shouldShowUserModal = false
                lastTargetUserId = nil
            }
        }
        .onChange(of: appState.shouldNavigateToProfileEdit) { _, shouldNavigate in
            if shouldNavigate {
                // 프로필 편집 네비게이션 처리
                withAnimation(.easeInOut(duration: 0.3)) {
                    // 세팅 화면으로 이동
                    activeScreen = .settings
                    // 프로필 설정으로 바로 네비게이션
                    settingsNavigationPath = [.profile]
                }
                // 상태 리셋
                appState.shouldNavigateToProfileEdit = false
            }
        }


        .overlay(
            // 하단 유저 모달 - 최적화된 조건부 렌더링
            VStack {
                Spacer()
                    .frame(minHeight: 52)
                
                if let targetUserId = appState.galaxyTargetUserId,
                   shouldShowUserModal,
                   appState.isGalaxyLoadingComplete, // 로딩 완료 후에만 표시
                   targetUserId == appState.currentUserId || // 현재 사용자이거나
                   (targetUserId != appState.currentUserId && appState.galaxyTargetUserId == targetUserId) { // 다른 사용자이고 실제로 해당 갤럭시를 보고 있는 경우
                    UserInfoModalView(
                        userId: targetUserId,
                        isOwnGalaxy: targetUserId == appState.currentUserId,
                        onAddMemory: targetUserId == appState.currentUserId ? {
                            activeScreen = .addMemory
                        } : nil,
                        diContainer: diContainer
                    )
                    .id("UserInfoModal-\(targetUserId.uuidString)-\(modalRefreshCounter)")
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .move(edge: .bottom).combined(with: .opacity)
                    ))
                    .opacity(appState.isGalaxyLoadingComplete ? 1.0 : 0.0) // 로딩 완료 시에만 표시
                }
            }
        )
        .animation(.easeInOut(duration: 0.4), value: shouldShowUserModal) // 애니메이션 시간 증가
        .animation(.easeInOut(duration: 0.4), value: modalRefreshCounter) // 애니메이션 시간 증가
    }
}
