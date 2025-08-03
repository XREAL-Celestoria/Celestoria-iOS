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
    @Environment(\.dismiss) private var dismiss
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
        ZStack(alignment: .bottom) {
            // Background
            Colors.BackgroundBlack
                .ignoresSafeArea()
            
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(thumbnails, id: \.self) { thumbnail in
                        Button(action: {
                            selectedThumbnail = thumbnail
                        }) {
                            ZStack {
                                // Thumbnail image
                                Image(thumbnail)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: (UIScreen.main.bounds.width - 40) / 2, height: 190)
                                    .clipped()
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(
                                                isSelected(thumbnail: thumbnail)
                                                ? AnyShapeStyle(LinearGradient.GradientSub)
                                                : AnyShapeStyle(Colors.GrayStroke),
                                                lineWidth: isSelected(thumbnail: thumbnail) ? 1.5 : 1
                                            )
                                    )
                                
                                if isSelected(thumbnail: thumbnail) {
                                    Image("Check-Circle")
                                        .frame(width: 24, height: 24)
                                        .offset(x: 68, y: -68)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)
                .padding(.bottom, 120)
            }
            
            VStack {
                iOSUploadButton(
                    title: "Save",
                    action: {
                        if let selected = selectedThumbnail,
                           let index = thumbnails.firstIndex(of: selected) {
                            Task {
                                await settingViewModel.updateThumbnail(thumbnailId: String(index + 1))
                                dismiss()
                            }
                        }
                    },
                    isEnabled: selectedThumbnail != nil
                )
                .padding(.horizontal, 24)
                .padding(.bottom, 30)
            }
            .background(LinearGradient.BtnBackGrad)
        }
        .navigationTitle("Thumbnail")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    Image("backButton")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                }
            }
        }
    }
}
