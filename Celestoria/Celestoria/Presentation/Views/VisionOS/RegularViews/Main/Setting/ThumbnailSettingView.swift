//
//  ThumbnailSettingView.swift
//  Celestoria
//
//  Created by Park Seyoung on 5/25/25.
//

import SwiftUI

// MARK: - Thumbnail Setting View
struct ThumbnailSettingView: View {
    @EnvironmentObject var viewModel: SettingViewModel
    @State private var showThumbnailSelector = false
    @State private var selectedThumbnail: Int = 0
    @State private var isEditing = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 40) {
            Text("Thumbnail")
                .font(.system(size: 29, weight: .bold))
                .foregroundColor(.NebulaWhite)
                .padding(.top, 35)
                .padding(.horizontal, 55)
            
            Button(action: {
                if isEditing {
                    showThumbnailSelector = true
                }
            }) {
                ZStack {
                    Image(viewModel.getThumbnailImageName(from: viewModel.profile?.spaceThumbnailId))
                        .resizable()
                        .scaledToFill()
                        .frame(width: 434, height: 456)
                        .cornerRadius(19)
                    if isEditing {
                        // 오버레이 레이어
                        RoundedRectangle(cornerRadius: 19)
                            .fill(Color.black.opacity(0.5))
                            .frame(width: 434, height: 456)
                        
                        // Change Photo 텍스트
                        Text("Change Photo")
                            .font(.system(size: 29, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity)
            .padding(.top, 20)
            
            Button(action: {
                isEditing.toggle()
            }) {
                Text(isEditing ? "Cancel" : "Edit")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.NebulaWhite)
            }
            .frame(maxWidth: .infinity)
            .buttonStyle(.plain)
            
            Spacer()
        }
        .sheet(isPresented: $showThumbnailSelector) {
            ThumbnailSelectorView(
                selectedThumbnail: $selectedThumbnail,
                isPresented: $showThumbnailSelector,
                isEditing: $isEditing,
                viewModel: viewModel
            )
        }
        .onAppear {
            if let currentId = viewModel.profile?.spaceThumbnailId,
               let intId = Int(currentId) {
                selectedThumbnail = intId - 1
            }
        }
    }
}

// MARK: - Thumbnail Selector View
struct ThumbnailSelectorView: View {
    @Binding var selectedThumbnail: Int
    @Binding var isPresented: Bool
    @Binding var isEditing: Bool
    @State private var initialThumbnail: Int
    let viewModel: SettingViewModel
    
    let thumbnails = ["Thumbnail1", "Thumbnail2", "Thumbnail3", "Thumbnail4", "Thumbnail5", "Thumbnail6"]
    
    init(selectedThumbnail: Binding<Int>, isPresented: Binding<Bool>, isEditing: Binding<Bool>, viewModel: SettingViewModel) {
        self._selectedThumbnail = selectedThumbnail
        self._isPresented = isPresented
        self._isEditing = isEditing
        self._initialThumbnail = State(initialValue: selectedThumbnail.wrappedValue)
        self.viewModel = viewModel
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 50) {
                HStack {
                    Text("Change Thumbnail")
                        .font(.system(size: 29, weight: .bold))
                        .foregroundColor(.NebulaWhite)
                    
                    Spacer()
                    
                    Button(action: {
                        isPresented = false
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color(hex: "E7E7E7").opacity(0.2))
                                .frame(width: 44, height: 44)
                            
                            Image(systemName: "xmark")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20, height: 20)
                                .foregroundColor(.NebulaWhite)
                        }
                    }
                    .buttonStyle(MainButtonStyle())
                }
                .padding(.horizontal, 60)
                .padding(.top, 40)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 20), count: 3), spacing: 20) {
                    ForEach(0..<6) { index in
                        Button(action: {
                            selectedThumbnail = index
                        }) {
                            ThumbnailCell(
                                image: thumbnails[index],
                                isSelected: selectedThumbnail == index
                            )
                        }
                        .buttonStyle(MainButtonStyle())
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                            .inset(by: 0.25)
                            .stroke(Color(red: 0.62, green: 0.62, blue: 0.62), lineWidth: 0.5)
                        )
                    }
                }
                .padding(.horizontal, 60)
                .padding(.top, 20)
                
                Button(action: {
                    Task {
                        // Convert thumbnail index to ID (adding 1 because IDs start from 1)
                        await viewModel.updateThumbnail(thumbnailId: String(selectedThumbnail + 1))
                        isPresented = false
                        isEditing = false
                    }
                }) {
                    Text("SAVE")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(selectedThumbnail != initialThumbnail ? .black : .black.opacity(0.3))
                        .frame(maxWidth: .infinity)
                        .frame(height: 76)
                        .background(
                            selectedThumbnail != initialThumbnail ?
                            LinearGradient(
                                stops: [
                                    Gradient.Stop(color: Color(red: 0.65, green: 0.91, blue: 1), location: 0.00),
                                    Gradient.Stop(color: Color(red: 0.71, green: 0.79, blue: 1), location: 1.00),
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            ) :
                            LinearGradient(
                                stops: [
                                    Gradient.Stop(color: Color(red: 0.67, green: 0.72, blue: 0.78), location: 0.00),
                                    Gradient.Stop(color: Color(red: 0.51, green: 0.62, blue: 0.73), location: 1.00),
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .cornerRadius(16)
                }
                .disabled(selectedThumbnail == initialThumbnail)
                .padding(.horizontal, 60)
                .padding(.bottom, 40)
                .buttonStyle(.plain)
            }
        }
        .frame(width: 778, height: 849)
        .background(
            LinearGradient(
                stops: [
                    Gradient.Stop(color: Color(hex: "17191E"), location: 0.00),
                    Gradient.Stop(color: Color(hex: "17191E"), location: 0.66),
                    Gradient.Stop(color: Color(red: 0.33, green: 0.77, blue: 1).opacity(0.5), location: 1.00),
                ],
                startPoint: UnitPoint(x: 0.5, y: 0),
                endPoint: UnitPoint(x: 0.5, y: 1)
            )
        )
        .cornerRadius(46)
        .shadow(color: Color(red: 0.42, green: 0.73, blue: 1), radius: 15)
        // 이 윈도우는 stroke가 얇아서 GradientBorderContainer 이거 당장은 못 씀
        .overlay(
            RoundedRectangle(cornerRadius: 46)
                .inset(by: 1.5)
                .stroke(.white, lineWidth: 3)
        )
    }
}

// MARK: - Thumbnail Cell
struct ThumbnailCell: View {
    let image: String
    let isSelected: Bool
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topTrailing) {
                // Base Image
                Image(image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                
                // Overlay when selected
                if isSelected {
                    Color.black.opacity(0.5)
                    
                    // Check Circle
                    Image("Check-Circle")
                        .frame(width: 30, height: 30)
                        .padding([.top, .trailing], 12)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .frame(width: 210, height: 240)
    }
}
