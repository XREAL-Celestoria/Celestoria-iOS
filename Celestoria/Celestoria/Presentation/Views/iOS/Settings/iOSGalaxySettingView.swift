//
//  iOSGalaxySettingView.swift
//  Celestoria
//
//  Created by Minjun Kim on 7/20/25.
//


//
//  iOSGalaxySettingView.swift
//  Celestoria
//
//  Created by Claude on 2025/07/20.
//

import SwiftUI

struct iOSGalaxySettingView: View {
    @StateObject private var galaxyViewModel: GalaxyViewModel
    @State private var selectedStarfield: String?
    let diContainer: DIContainer
    
    init(diContainer: DIContainer) {
        self.diContainer = diContainer
        _galaxyViewModel = StateObject(wrappedValue: diContainer.makeGalaxyViewModel())
    }
    
    private let starfields: [String] = [
        "Starfield-1", "Starfield-2", "Starfield-3", "Starfield-4",
        "Starfield-5", "Starfield-6", "Starfield-7", "Starfield-8"
    ]
    
    private func isSelected(starfield: String) -> Bool {
        if let selected = selectedStarfield {
            return selected == starfield
        }
        return galaxyViewModel.selectedImage == starfield
    }
    
    var body: some View {
        ZStack {
            // Background
            Color.black
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Grid of galaxy options
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        ForEach(starfields, id: \.self) { starfield in
                            Button(action: {
                                selectedStarfield = starfield
                            }) {
                                ZStack {
                                    // Galaxy image
                                    Image(starfield)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(height: 180)
                                        .clipped()
                                        .cornerRadius(16)
                                    
                                    if isSelected(starfield: starfield) {
                                        // Selection overlay
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.white, lineWidth: 3)
                                        
                                        // Check mark
                                        VStack {
                                            HStack {
                                                Spacer()
                                                Circle()
                                                    .fill(Color.white)
                                                    .frame(width: 28, height: 28)
                                                    .overlay(
                                                        Image(systemName: "checkmark")
                                                            .font(.system(size: 14, weight: .bold))
                                                            .foregroundColor(.black)
                                                    )
                                                    .padding(8)
                                            }
                                            Spacer()
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 20)
                }
                
                // Save Button
                Button(action: {
                    if let selected = selectedStarfield {
                        galaxyViewModel.selectImage(with: selected)
                        galaxyViewModel.saveSelectedImage()
                    }
                }) {
                    Text("Save")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(Color.white)
                        )
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
                .disabled(selectedStarfield == nil && galaxyViewModel.selectedImage == nil)
            }
        }
        .navigationTitle("Galaxy")
        .navigationBarTitleDisplayMode(.inline)
    }
}