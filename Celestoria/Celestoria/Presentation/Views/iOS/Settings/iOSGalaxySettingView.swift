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
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = true
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
        return galaxyViewModel.isSelected(image: starfield)
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Background
            Colors.BackgroundBlack
                .ignoresSafeArea()
            
            // 메인 콘텐츠는 항상 렌더링
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(starfields, id: \.self) { starfield in
                        Button(action: {
                            galaxyViewModel.selectImage(with: starfield)
                        }) {
                            ZStack {
                                // Galaxy image
                                Image(starfield)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: (UIScreen.main.bounds.width - 40) / 2 , height: 180)
                                    .clipped()
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(
                                                isSelected(starfield: starfield)
                                                ? AnyShapeStyle(LinearGradient.GradientSub)
                                                : AnyShapeStyle(Colors.GrayStroke),
                                                lineWidth: isSelected(starfield: starfield) ? 1.5 : 1
                                            )
                                    )
                                
                                if isSelected(starfield: starfield) {
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
                iOSUploadButton (
                    title: "Save",
                    action: {
                        galaxyViewModel.saveSelectedImage()
                        dismiss()
                    },
                    isEnabled: galaxyViewModel.isUploadEnabled
                )
                .padding(.horizontal, 24)
                .padding(.bottom, 30)
            }
            .background(LinearGradient.BtnBackGrad)
            
            // 로딩 오버레이
            if isLoading {
                iOSUnifiedLoadingView.fullscreen(title: "Loading Galaxy Settings")
                    .opacity(isLoading ? 1.0 : 0.0)
                    .animation(.easeInOut(duration: 0.3), value: isLoading)
            }
        }
        .navigationTitle("Galaxy")
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
        .onAppear {
            // 초기 데이터 로딩 완료 후 로딩 상태 해제
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isLoading = false
            }
        }
    }
}
