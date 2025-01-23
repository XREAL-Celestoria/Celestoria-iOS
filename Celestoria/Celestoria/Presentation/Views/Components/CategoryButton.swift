//
//  CategoryButton.swift
//  Celestoria
//
//  Created by Park Seyoung on 1/23/25.
//

import SwiftUI

// MARK: - Category Button
struct CategoryButton: View {
    let category: Category
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        VStack {
            Button(action: action) {
                ZStack {
                    Circle()
                        .fill(
                            isSelected ? AnyShapeStyle(LinearGradient.GradientSub):
                            AnyShapeStyle(Color(hex:"1B212A")))
                        .stroke(
                            isSelected ?
                            AnyShapeStyle(LinearGradient.GradientSub) :
                            AnyShapeStyle(Color(hex:"1B212A")) ,
                            lineWidth: 0.5)
                        .frame(width: 50, height: 50)
                    Image(category.iconName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .foregroundColor(.NebulaWhite)
                }
            }
            Text(category.displayName)
                .fixedSize(horizontal: true, vertical: false)
                .foregroundStyle(
                    isSelected
                        ? AnyShapeStyle(LinearGradient.GradientSub)
                        : AnyShapeStyle(Color.NebulaWhite)
                )
                .font(.system(size: 15, weight: .regular))
                .padding(.top, 4)
        }
        .frame(width: 50)
    }
}
