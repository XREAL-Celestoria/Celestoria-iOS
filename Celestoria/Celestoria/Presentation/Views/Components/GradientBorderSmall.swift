//
//  GradientBorderSmall.swift
//  Celestoria
//
//  Created by Park Seyoung on 1/29/25.
//

import SwiftUI

struct GradientBorderContainerSmall: View {
    let content: AnyView

    init<Content: View>(@ViewBuilder content: () -> Content) {
        self.content = AnyView(content())
    }

    var body: some View {
        ZStack {
            // 테두리와 배경
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.NebulaBlack)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient.GradientMain,
                            lineWidth: 12 // 테두리 두께를 16에서 12로 조정
                        )
                )
                .frame(width: 720, height: 188) // 고정 크기 설정
            
            // 내부 컨텐츠
            content
                .padding(12) // 컨텐츠 내부 여백
                .background(Color.NebulaBlack) // 컨텐츠 배경
                .clipShape(RoundedRectangle(cornerRadius: 24)) // 내부 모양 맞추기
    
        }
    }
}
