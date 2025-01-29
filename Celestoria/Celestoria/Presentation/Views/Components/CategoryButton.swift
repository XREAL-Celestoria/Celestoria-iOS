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
                    // 배경 원형 버튼
                    Circle()
                        .fill(isSelected ? 
                            AnyShapeStyle(LinearGradient.GradientSub) :
                            AnyShapeStyle(Color(hex:"1B212A")))
                        .stroke(isSelected ?
                            AnyShapeStyle(LinearGradient.GradientSub) :
                            AnyShapeStyle(Color(hex:"1B212A")),
                            lineWidth: 0.5)
                        .frame(width: 50, height: 50)
                    
                    // 카테고리 아이콘 이미지
                    // .id 수정자를 사용하여 선택 상태가 변경될 때마다 이미지 뷰를 강제로 리프레시
                    // 이는 여러 카테고리 선택 시 이전 선택된 이미지가 잔상으로 남는 문제를 해결
                    Image(category.iconName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .foregroundStyle(isSelected ? 
                            LinearGradient.GradientSub : 
                            Color.NebulaWhite)
                        .id(isSelected)
                }
            }
            .buttonStyle(MainButtonStyle())
            // 버튼의 선택 상태에 따라 고유한 ID를 부여
            // 이를 통해 SwiftUI가 상태 변경을 명확히 인식하고 뷰를 적절히 업데이트
            .id(category.rawValue + (isSelected ? "-selected" : ""))
            
            // 카테고리 이름
            Text(category.displayName)
                .fixedSize(horizontal: true, vertical: false)
                .foregroundStyle(isSelected ?
                    AnyShapeStyle(LinearGradient.GradientSub) :
                    AnyShapeStyle(Color.NebulaWhite))
                .font(.system(size: 15, weight: .regular))
                .padding(.top, 4)
        }
        .frame(width: 50)
    }
}
