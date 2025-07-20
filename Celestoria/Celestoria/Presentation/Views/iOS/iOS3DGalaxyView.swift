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
    @Binding var selectedMemory: Memory?
    @Binding var showMemoryDetail: Bool
    let diContainer: DIContainer
    
    init(diContainer: DIContainer, selectedMemory: Binding<Memory?>, showMemoryDetail: Binding<Bool>) {
        self.diContainer = diContainer
        _galaxyViewModel = StateObject(wrappedValue: diContainer.makeGalaxyViewModel())
        _selectedMemory = selectedMemory
        _showMemoryDetail = showMemoryDetail
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
            camera.zFar = 2000 // Increased to see large skybox
            
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
            // Create large sphere for skybox (same as visionOS)
            let sphere = SCNSphere(radius: 1000) // Much larger radius like visionOS
            sphere.segmentCount = 48
            
            // Use unlit material for space background
            let material = SCNMaterial()
            material.lightingModel = .constant // Unlit material
            
            // Use selectedImage if available, otherwise use random starfield
            let starfieldName: String
            if let selected = parent.galaxyViewModel.selectedImage {
                starfieldName = selected
            } else {
                let starfieldCount = 18
                let randomIndex = Int.random(in: 1...starfieldCount)
                starfieldName = "Starfield-\(randomIndex)"
            }
            
            if let starfieldImage = UIImage(named: starfieldName) {
                material.diffuse.contents = starfieldImage
                print("Initial background set to: \(starfieldName)")
            } else {
                print("Warning: Failed to load starfield image: \(starfieldName), using default")
                material.diffuse.contents = UIImage(named: "Starfield-1")
            }
            
            material.isDoubleSided = true
            material.cullMode = .front // Show inside of sphere
            
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
            guard let material = backgroundNode?.geometry?.firstMaterial else { 
                print("Warning: Background node or material is not initialized yet")
                return
            }
            
            // Use selectedImage (starfield) instead of spaceThumbnail for background
            if let starfieldName = parent.galaxyViewModel.selectedImage {
                if let backgroundImage = UIImage(named: starfieldName) {
                    material.diffuse.contents = backgroundImage
                    print("Background updated with: \(starfieldName)")
                } else {
                    print("Warning: Failed to load starfield image: \(starfieldName), using default")
                    material.diffuse.contents = UIImage(named: "Starfield-1")
                }
            } else {
                print("Warning: No selectedImage, using default Starfield-1")
                material.diffuse.contents = UIImage(named: "Starfield-1")
            }
        }
        
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let scnView = gesture.view as? SCNView else { return }
            
            let location = gesture.location(in: scnView)
            let hitResults = scnView.hitTest(location, options: [:])
            
            // Debug logging
            print("Tap detected at: \(location)")
            print("Hit results count: \(hitResults.count)")
            
            if let result = hitResults.first {
                print("Hit node: \(result.node)")
                print("Hit node name: \(result.node.name ?? "no name")")
                
                // Check if the hit node is a child of iOS3DMemoryStarNode
                var checkNode: SCNNode? = result.node
                while checkNode != nil {
                    if let memoryNode = checkNode as? iOS3DMemoryStarNode {
                        AudioServicesPlaySystemSound(1104)
                        parent.selectedMemory = memoryNode.memory
                        parent.showMemoryDetail = true
                        print("Memory selected: \(memoryNode.memory.title)")
                        return
                    }
                    checkNode = checkNode?.parent
                }
                print("No memory node found in hierarchy")
            } else {
                print("No hit results")
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
            iOS3DGalaxyView(
                diContainer: diContainer,
                selectedMemory: $selectedMemory,
                showMemoryDetail: $showMemoryDetail
            )
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