//
//  GalaxyView.swift
//  Celestoria
//
//  Created by Park Seyoung on 1/20/25.
//

import SwiftUI

struct GalaxyView: View {
    @EnvironmentObject var appModel: AppModel
    @EnvironmentObject var galaxyViewModel: GalaxyViewModel
    @State private var selectedSection: GalaxySection = .galaxyBackground
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                LeftGalaxyView(selectedSection: $selectedSection)
                    .frame(width: geometry.size.width * 0.38)
                
                RightGalaxyView(selectedSection: selectedSection)
                    .frame(width: geometry.size.width * 0.62)
            }
        }
        .background(Color.NebulaBlack.ignoresSafeArea())
        .alert("오류", isPresented: $showError) {
            Button("확인", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
}

// MARK: - Left View
private struct LeftGalaxyView: View {
    @Binding var selectedSection: GalaxySection
    @EnvironmentObject var appModel: AppModel
    @EnvironmentObject var galaxyViewModel: GalaxyViewModel
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    
    var body: some View {
        VStack(spacing: 20) {
            // 네비게이션 바
            NavigationBar(
                title: "Galaxy",
                action: {
                    appModel.activeScreen = .main
                },
                buttonImageString: "chevron.left"
            )
            .padding(.horizontal, 4)
            .padding(.top, 4)
            
            Spacer()
                .frame(height: 20)
            
            // 메뉴 버튼들
            VStack(spacing: 24) {
                ForEach(galaxyMenuItems, id: \.title) { item in
                    NavigationMenuButton(
                        menuItem: item,
                        isSelected: selectedSection.rawValue == item.title,
                        action: {
                            if let section = GalaxySection(rawValue: item.title) {
                                selectedSection = section
                            }
                        }
                    )
                }
            }
            
            Spacer()
            
        }
        .alert("오류", isPresented: $showError) {
            Button("확인", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
}

// MARK: - Right View
private struct RightGalaxyView: View {
    let selectedSection: GalaxySection
    
    var body: some View {
        ZStack {
            VisualEffectBlur(style: .systemMaterial)
                .edgesIgnoringSafeArea(.all)
            
            Rectangle()
                .fill(Color.clear)
                .overlay(
                    Color.NebulaBlack.opacity(0.3)
                        .shadow(.inner(color: Color.NebulaWhite.opacity(0.8), radius: 24))
                )
                .edgesIgnoringSafeArea(.all)
            
            // Content
            switch selectedSection {
            case .galaxyBackground:
                GalaxyBackgroundView()
            }
        }
    }
}

// MARK: - Galaxy Background View
private struct GalaxyBackgroundView: View {
    @EnvironmentObject var galaxyViewModel: GalaxyViewModel
    var body: some View {
        let gridButtonItems = StarField.allCases.map {
            GridButtonItem(id: $0.hashValue, imageName: $0.imageName)
        }
        
        GalaxyButtonGrid(items: gridButtonItems)
            .padding()
    }
}

private struct GalaxyButtonGrid: View {
    let items: [GridButtonItem]
    @EnvironmentObject var galaxyViewModel: GalaxyViewModel
    let columns: Int = 3
    
    var body: some View {
        let gridItems = Array(repeating: GridItem(.fixed(215), spacing: 20), count: columns)
        
        VStack {
            HStack {
                Text("Galaxy Background")
                    .font(.system(size: 29, weight: .bold))
                    .foregroundColor(.NebulaWhite)
                    .padding(.leading, 55)
                Spacer()
            }
            .padding(.top, 35)
            
            LazyVGrid(columns: gridItems, spacing: 20) {
                ForEach(items) { item in
                    Button(action: {
                        galaxyViewModel.selectImage(with: item.imageName)
                    }) {
                        ZStack {
                            Image(item.imageName)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 215, height: 195)
                                .clipped()
                                .cornerRadius(20)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(
                                            galaxyViewModel.isSelected(image: item.imageName)
                                            ? AnyShapeStyle(LinearGradient.GradientSub)
                                            : AnyShapeStyle(Color(hex: "9D9D9D")),
                                            lineWidth: galaxyViewModel.isSelected(image: item.imageName)
                                            ? 2
                                            : 1
                                        )
                                )
                            
                            if galaxyViewModel.isSelected(image: item.imageName) {
                                Image("Check-Circle")
                                    .frame(width: 30, height: 30)
                                    .offset(x: 80, y: -72)
                            }
                        }
                    }
                    .frame(width: 215, height: 195)
                }
            }
            .padding(.top, 30)
            
            Spacer()
            
            MainButton(
                title: "Save", action: {
                    galaxyViewModel.saveSelectedImage()
                },
                isEnabled: galaxyViewModel.isUploadEnabled 
            )
            .padding(.bottom, 60)
            .disabled(!galaxyViewModel.isUploadEnabled)

        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

// MARK: - Enums
struct GridButtonItem: Identifiable {
    let id: Int
    let imageName: String
}

enum GalaxySection: String {
    case galaxyBackground = "Galaxy Background"
}

#Preview {
    GalaxyView()
}
