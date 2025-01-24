//
//  TextField+.swift
//  Celestoria
//
//  Created by Park Seyoung on 1/24/25.
//

import SwiftUI

extension View {
    /// 텍스트 입력 길이를 제한하는 Modifier를 적용합니다.
    /// - Parameters:
    ///   - text: `@Binding`으로 연결된 텍스트 상태.
    ///   - length: 허용 가능한 최대 문자 길이.
    /// - Returns: 입력 길이를 제한하는 `View`.
    func maxLength(text: Binding<String>, length: Int) -> some View {
        self.modifier(MaxLengthModifier(text: text, maxLength: length))
    }
}

/// 텍스트 입력 길이를 제한하는 ViewModifier.
struct MaxLengthModifier: ViewModifier {
    @Binding var text: String
    let maxLength: Int

    func body(content: Content) -> some View {
        content
            .onChange(of: text) { newValue in
                if newValue.count > maxLength {
                    text = String(newValue.prefix(maxLength))
                }
            }
    }
}
