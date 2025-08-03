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

struct iOS3DGalaxyContainerView: View {
    let diContainer: DIContainer
    @EnvironmentObject var appState: AppState
    @StateObject private var galaxyViewModel: GalaxyViewModel
    @State private var showSettings = false
    @State private var showAddMemory = false
    @State private var containerOpacity: Double = 0
    
    init(diContainer: DIContainer) {
        self.diContainer = diContainer
        _galaxyViewModel = StateObject(wrappedValue: diContainer.makeGalaxyViewModel())
    }
    
    var body: some View {
        ZStack {
            iOS3DGalaxyView(
                galaxyViewModel: galaxyViewModel,
                appState: appState,
                diContainer: diContainer
            )
            
            VStack {
                // Top bar with settings button
                HStack {
                    Spacer()
                    
                    Button(action: {
                        showSettings = true
                    }) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                            .padding(12)
                            .background(
                                Circle()
                                    .fill(Color.black.opacity(0.5))
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                    )
                            )
                    }
                    .padding(.trailing, 20)
                    .padding(.top, 50) // Account for safe area
                }
                
                Spacer()
                
                if let targetUserId = appState.galaxyTargetUserId {
                    UserInfoModalView(
                        userId: targetUserId,
                        isOwnGalaxy: targetUserId == appState.currentUserId,
                        onAddMemory: {
                            showAddMemory = true
                        },
                        diContainer: diContainer
                    )
                    .padding(.bottom, 20)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                    .id("userInfoModal-\(targetUserId)-\(appState.refreshMainView)")
                }
            }
            .transition(.opacity)
        }
        .opacity(containerOpacity)
        .animation(.easeInOut(duration: 1.0), value: containerOpacity)
        .onAppear {
            // 컨테이너가 나타날 때 페이드인
            withAnimation(.easeInOut(duration: 1.0).delay(0.3)) {
                containerOpacity = 1
            }
        }
        .fullScreenCover(isPresented: $showAddMemory) {
            iOSAddMemoryContentView(diContainer: diContainer)
        }
        .fullScreenCover(isPresented: $showSettings) {
            iOSSettingsView(diContainer: diContainer)
        }
        .fullScreenCover(isPresented: $appState.showMemoryDetail) {
            if let memory = appState.selectedMemoryForDetail {
                iOSMemoryDetailView(memory: memory, diContainer: diContainer)
            }
        }
        .onChange(of: appState.refreshMainView) { _, shouldRefresh in
            if shouldRefresh {
                // 메인뷰 새로고침
                galaxyViewModel.refreshGalaxy()
                appState.refreshMainView = false
            }
        }
    }
}
