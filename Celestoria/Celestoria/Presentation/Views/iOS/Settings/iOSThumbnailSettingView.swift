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
    @State private var isEditMode = false
    @State private var showThumbnailSelector = false
    let diContainer: DIContainer
    
    init(diContainer: DIContainer) {
        self.diContainer = diContainer
        _settingViewModel = StateObject(wrappedValue: diContainer.settingViewModel)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Current Thumbnail
                VStack(spacing: 16) {
                    if let thumbnailId = settingViewModel.profile?.spaceThumbnailId {
                        Image(thumbnailName(for: thumbnailId))
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 250)
                            .clipped()
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    } else {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 250)
                            .overlay(
                                VStack {
                                    Image(systemName: "photo")
                                        .font(.system(size: 50))
                                        .foregroundColor(.gray)
                                    Text("No thumbnail set")
                                        .font(.system(size: 16))
                                        .foregroundColor(.gray)
                                }
                            )
                    }
                    
                    Text("This thumbnail will be displayed as the background of your space")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                // Edit Button
                Button(action: {
                    showThumbnailSelector = true
                }) {
                    Text("Change Thumbnail")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(LinearGradient.GradientMain)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle("Space Thumbnail")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showThumbnailSelector) {
            iOSThumbnailSelectorView(settingViewModel: settingViewModel)
        }
    }
}

struct iOSThumbnailSelectorView: View {
    @ObservedObject var settingViewModel: SettingViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedThumbnail: String?
    
    private let thumbnails = (1...6).map { "Thumbnail\($0)" }
    
    private func isSelected(thumbnail: String) -> Bool {
        if selectedThumbnail == thumbnail {
            return true
        }
        
        if selectedThumbnail == nil,
           let thumbnailId = settingViewModel.profile?.spaceThumbnailId,
           let intId = Int(thumbnailId), intId >= 1 && intId <= 6 {
            let currentThumbnailName = "Thumbnail\(intId)"
            return currentThumbnailName == thumbnail
        }
        
        return false
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Select a space thumbnail")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                        ForEach(thumbnails, id: \.self) { thumbnail in
                            Button(action: {
                                selectedThumbnail = thumbnail
                            }) {
                                ZStack {
                                    Image(thumbnail)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(height: 120)
                                        .clipped()
                                        .cornerRadius(12)
                                    
                                    if isSelected(thumbnail: thumbnail) {
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(LinearGradient.GradientMain, lineWidth: 3)
                                        
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 30))
                                            .foregroundStyle(LinearGradient.GradientMain)
                                            .background(Circle().fill(Color.white))
                                            .position(x: 20, y: 20)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Select Thumbnail")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        if let selected = selectedThumbnail {
                            Task {
                                // Extract number from thumbnail name
                                let thumbnailId = selected.replacingOccurrences(of: "Thumbnail", with: "")
                                await settingViewModel.updateThumbnail(thumbnailId: thumbnailId)
                                dismiss()
                            }
                        }
                    }
                    .disabled(selectedThumbnail == nil || (settingViewModel.profile?.spaceThumbnailId != nil && selectedThumbnail == "spaceThumbnail\(String(format: "%02d", Int(settingViewModel.profile?.spaceThumbnailId ?? "1") ?? 1))"))
                }
            }
        }
        .onAppear {
            if let thumbnailId = settingViewModel.profile?.spaceThumbnailId,
               let intId = Int(thumbnailId), intId >= 1 && intId <= 6 {
                selectedThumbnail = "Thumbnail\(intId)"
            }
        }
    }
}