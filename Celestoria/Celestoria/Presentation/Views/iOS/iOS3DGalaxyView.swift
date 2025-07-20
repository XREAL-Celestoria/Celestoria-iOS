//
//  iOS3DGalaxyView.swift
//  Celestoria
//
//  Created by Minjun Kim on 7/20/25.
//


import SwiftUI
import SceneKit
import AudioToolbox

struct iOS3DGalaxyView: UIViewRepresentable {
    @EnvironmentObject var appState: AppState
    @StateObject private var galaxyViewModel: GalaxyViewModel
    @State private var selectedMemory: Memory?
    @State private var showMemoryDetail = false
    @State private var showUserInfo = true
    
    init(diContainer: DIContainer) {
        _galaxyViewModel = StateObject(wrappedValue: diContainer.makeGalaxyViewModel())
    }
    
    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.backgroundColor = UIColor.black
        scnView.autoenablesDefaultLighting = false
        scnView.allowsCameraControl = true
        scnView.showsStatistics = false
        
        let scene = SCNScene()
        scnView.scene = scene
        
        context.coordinator.setupScene(scene)
        context.coordinator.loadMemories()
        
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        scnView.addGestureRecognizer(tapGesture)
        
        return scnView
    }
    
    func updateUIView(_ uiView: SCNView, context: Context) {
        context.coordinator.updateMemories()
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject {
        var parent: iOS3DGalaxyView
        var memoryNodes: [UUID: iOS3DMemoryStarNode] = [:]
        var scene: SCNScene?
        var backgroundNode: SCNNode?
        var cameraNode: SCNNode?
        
        init(_ parent: iOS3DGalaxyView) {
            self.parent = parent
        }
        
        @MainActor
        func setupScene(_ scene: SCNScene) {
            self.scene = scene
            
            setupCamera(in: scene)
            setupLighting(in: scene)
            setupBackground(in: scene)
        }
        
        private func setupCamera(in scene: SCNScene) {
            let camera = SCNCamera()
            camera.fieldOfView = 60
            camera.zNear = 0.1
            camera.zFar = 100
            
            cameraNode = SCNNode()
            cameraNode?.camera = camera
            cameraNode?.position = SCNVector3(x: 0, y: 0, z: 5)
            scene.rootNode.addChildNode(cameraNode!)
        }
        
        private func setupLighting(in scene: SCNScene) {
            let ambientLight = SCNLight()
            ambientLight.type = .ambient
            ambientLight.color = UIColor(white: 0.3, alpha: 1.0)
            
            let ambientNode = SCNNode()
            ambientNode.light = ambientLight
            scene.rootNode.addChildNode(ambientNode)
        }
        
        @MainActor
        private func setupBackground(in scene: SCNScene) {
            let sphere = SCNSphere(radius: 50)
            sphere.segmentCount = 48
            
            let material = SCNMaterial()
            if let backgroundName = parent.galaxyViewModel.spaceThumbnail {
                material.diffuse.contents = UIImage(named: backgroundName)
            } else {
                material.diffuse.contents = UIImage(named: "spaceThumbnail01")
            }
            material.isDoubleSided = true
            material.cullMode = .front
            
            sphere.materials = [material]
            
            backgroundNode = SCNNode(geometry: sphere)
            scene.rootNode.addChildNode(backgroundNode!)
        }
        
        func loadMemories() {
            
            Task { @MainActor in
                do {
                    if let targetUserId = parent.appState.galaxyTargetUserId,
                       targetUserId != parent.appState.currentUserId {
                        try await parent.galaxyViewModel.fetchMemoriesFromOtherUser(userId: targetUserId)
                    } else {
                        try await parent.galaxyViewModel.fetchCurrentUserMemories()
                    }
                    
                    updateMemoryNodes()
                } catch {
                    print("Error loading memories: \(error)")
                }
            }
        }
        
        @MainActor
        func updateMemories() {
            updateMemoryNodes()
            updateBackground()
        }
        
        @MainActor
        private func updateMemoryNodes() {
            guard let scene = scene else { return }
            
            let currentMemoryIds = Set(parent.galaxyViewModel.memories.map { $0.id })
            let existingMemoryIds = Set(memoryNodes.keys)
            
            let toRemove = existingMemoryIds.subtracting(currentMemoryIds)
            for id in toRemove {
                memoryNodes[id]?.removeFromParentNode()
                memoryNodes.removeValue(forKey: id)
            }
            
            for memory in parent.galaxyViewModel.memories {
                if memoryNodes[memory.id] == nil {
                    let node = iOS3DMemoryStarNode(memory: memory)
                    scene.rootNode.addChildNode(node)
                    memoryNodes[memory.id] = node
                    
                    node.startPulseAnimation()
                } else if let node = memoryNodes[memory.id] {
                    node.updateMemory(memory)
                }
            }
        }
        
        @MainActor
        private func updateBackground() {
            guard let material = backgroundNode?.geometry?.firstMaterial else { return }
            
            if let backgroundName = parent.galaxyViewModel.spaceThumbnail {
                material.diffuse.contents = UIImage(named: backgroundName)
            }
        }
        
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let scnView = gesture.view as? SCNView else { return }
            
            let location = gesture.location(in: scnView)
            let hitResults = scnView.hitTest(location, options: [:])
            
            if let result = hitResults.first,
               let memoryNode = result.node as? iOS3DMemoryStarNode {
                AudioServicesPlaySystemSound(1104)
                parent.selectedMemory = memoryNode.memory
                parent.showMemoryDetail = true
            }
        }
    }
}

struct iOS3DGalaxyContainerView: View {
    let diContainer: DIContainer
    @EnvironmentObject var appState: AppState
    @State private var selectedMemory: Memory?
    @State private var showMemoryDetail = false
    @State private var showSettings = false
    @State private var showAddMemory = false
    
    var body: some View {
        ZStack {
            iOS3DGalaxyView(diContainer: diContainer)
                .edgesIgnoringSafeArea(.all)
            
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
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
        }
        .sheet(isPresented: $showMemoryDetail) {
            if let memory = selectedMemory {
                iOSMemoryDetailView(memory: memory, diContainer: diContainer)
            }
        }
        .sheet(isPresented: $showAddMemory) {
            NavigationView {
                iOSAddMemoryView(diContainer: diContainer)
            }
        }
        .sheet(isPresented: $showSettings) {
            NavigationView {
                iOSSettingsView(diContainer: diContainer)
            }
        }
    }
}

struct UserInfoModalView: View {
    let userId: UUID
    let isOwnGalaxy: Bool
    let onAddMemory: () -> Void
    let diContainer: DIContainer
    @State private var userProfile: UserProfile?
    @State private var memoryCount: Int = 0
    
    var body: some View {
        HStack(spacing: 16) {
            if let profile = userProfile {
                AsyncImage(url: URL(string: profile.profileImageURL ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                }
                .frame(width: 60, height: 60)
                .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(profile.name)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("\(memoryCount) memories")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                if isOwnGalaxy {
                    Button(action: onAddMemory) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                    }
                }
            } else {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
        .task {
            await loadUserInfo()
        }
    }
    
    private func loadUserInfo() async {
        do {
            // Load user profile
            userProfile = try await diContainer.profileUseCase.fetchProfileByUserId(userId: userId)
            
            // Load memory count
            let memories = try await diContainer.memoryUseCase.execute(for: userId)
            memoryCount = memories.count
        } catch {
            print("Error loading user info: \(error)")
            // Set default values on error
            userProfile = UserProfile(
                id: UUID(),
                userId: userId,
                name: "Unknown",
                profileImageURL: nil,
                profileKey: nil,
                spaceThumbnailId: nil,
                createdAt: Date(),
                starfield: nil
            )
            memoryCount = 0
        }
    }
}