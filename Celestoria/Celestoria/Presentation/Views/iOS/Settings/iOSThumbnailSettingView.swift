//
//  iOSThumbnailSettingView.swift
//  Celestoria
//
//  Created by Minjun Kim on 7/20/25.
//


import SwiftUI

// Helper function to map thumbnail IDs to asset names
private func thumbnailName(for id: String) -> String {
    if let intId = Int(id), intId >= 1 && intId <= 6 {
        return "Thumbnail\(intId)"
    } else {
        return "Thumbnail1"
    }
}

struct iOSThumbnailSettingView: View {
    @StateObject private var settingViewModel: SettingViewModel
    @State private var selectedThumbnail: String?
    let diContainer: DIContainer
    
    init(diContainer: DIContainer) {
        self.diContainer = diContainer
        _settingViewModel = StateObject(wrappedValue: diContainer.settingViewModel)
    }
    
    private let thumbnails = ["Thumbnail1", "Thumbnail2", "Thumbnail3", "Thumbnail4", "Thumbnail5", "Thumbnail6"]
    
    private func isSelected(thumbnail: String) -> Bool {
        if let selected = selectedThumbnail {
            return selected == thumbnail
        }
        if let thumbnailId = settingViewModel.profile?.spaceThumbnailId {
            return thumbnail == thumbnailName(for: thumbnailId)
        }
        return false
    }
    
    var body: some View {
        ZStack {
            // Background
            Color.black
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Grid of thumbnail options
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        ForEach(thumbnails, id: \.self) { thumbnail in
                            Button(action: {
                                selectedThumbnail = thumbnail
                            }) {
                                ZStack {
                                    // Thumbnail image
                                    Image(thumbnail)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(height: 180)
                                        .clipped()
                                        .cornerRadius(16)
                                    
                                    if isSelected(thumbnail: thumbnail) {
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
                    if let selected = selectedThumbnail,
                       let index = thumbnails.firstIndex(of: selected) {
                        Task {
                            await settingViewModel.updateThumbnail(thumbnailId: String(index + 1))
                        }
                    }
                }) {
                    Text("Save")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(Colors.NebulaBlack)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(LinearGradient.GradientSub)
                        )
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
                .disabled(selectedThumbnail == nil)
            }
        }
        .navigationTitle("Thumbnail")
        .navigationBarTitleDisplayMode(.inline)
    }
}
