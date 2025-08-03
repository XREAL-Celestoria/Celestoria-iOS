//
//  iOSAddMemoryComponents.swift
//  Celestoria
//
//  Created by Seyoung Park on 8/3/25.
//

import SwiftUI

// MARK: - iOSCategoryButton
struct iOSCategoryButton: View {
    let category: Category
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        VStack {
            Button(action: action) {
                ZStack {
                    // 배경 원형 버튼
                    Circle()
                        .fill(isSelected ? 
                            AnyShapeStyle(LinearGradient.GradientSub) :
                                AnyShapeStyle(Colors.IconBackground))
                        .stroke(isSelected ?
                            AnyShapeStyle(LinearGradient.GradientSub) :
                            AnyShapeStyle(Colors.IconBackground),
                            lineWidth: 0.5)
                        .frame(width: 50, height: 50)
                    
                    Image(category.iconName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .foregroundStyle(isSelected ? 
                            AnyShapeStyle(LinearGradient.GradientSub) : 
                            AnyShapeStyle(Colors.NonCheckedBoxStroke))
                        .id(isSelected)
                }
            }
            .buttonStyle(iOSMainButtonStyle())
            .id(category.rawValue + (isSelected ? "-selected" : ""))
            
            // 카테고리 이름
            Text(category.displayName)
                .fontStyle(Fonts.caption1)
                .foregroundStyle(isSelected ?
                    AnyShapeStyle(LinearGradient.GradientSub) :
                    AnyShapeStyle(Colors.NonCheckedBoxStroke))
                .padding(.top, 4)
        }
        .frame(width: 84)
    }
}

// MARK: - iOSUploadProgressView
struct iOSUploadProgressView: View {
    let progress: Double
    let fileSize: String
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Uploading Memory")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
            
            Text("Uploading \(fileSize) video file...")
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.8))
            
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(1.5)
                .padding(.top, 10)
        }
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Colors.NebulaBlack)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
}
