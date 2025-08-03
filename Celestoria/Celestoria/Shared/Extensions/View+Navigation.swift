//
//  View+Navigation.swift
//  Celestoria
//
//  Created by Assistant on 1/16/25.
//

import SwiftUI

extension View {
    /// 커스텀 네비게이션 뷰를 생성하는 함수
    /// - Parameters:
    ///   - title: 네비게이션 타이틀
    ///   - onBack: 뒤로가기 액션 (기본값: nil)
    /// - Returns: NavigationView로 감싸진 뷰
    func customNavigationView(title: String, onBack: (() -> Void)? = nil) -> some View {
        NavigationView {
            self
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarBackButtonHidden(true)
                .navigationBarItems(
                    leading: Button(action: {
                        onBack?()
                    }) {
                        Image("backButton")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                    }
                )
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    /// 커스텀 네비게이션바만 설정하는 함수 (NavigationView 없이)
    /// - Parameters:
    ///   - title: 네비게이션 타이틀
    ///   - onBack: 뒤로가기 액션 (기본값: nil)
    /// - Returns: 네비게이션바가 설정된 뷰
    func customNavigationBar(title: String, onBack: (() -> Void)? = nil) -> some View {
        self
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(onBack != nil)
            .toolbar {
                if let onBack = onBack {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: onBack) {
                            Image("backButton")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)
                        }
                    }
                } else {
                    // NavigationStack에서 기본 뒤로가기 버튼을 커스텀 이미지로 변경
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            // NavigationStack의 기본 뒤로가기 동작
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
} 
