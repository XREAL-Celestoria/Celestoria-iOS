//
//  NavigationBarWithMenu.swift
//  Celestoria
//
//  Created by Minjun Kim on 2/4/25.
//

import SwiftUI

struct NavigationBarWithMenu: View {
    let title: String
    let leftAction: () -> Void
    let leftButtonImageString: String
    
    // 메뉴의 각 버튼에 들어갈 action을 전달합니다.
    let reportAction: () -> Void
    let blockAction: () -> Void
    
    @State private var isMenuShown: Bool = false
    
    var body: some View {
        // 원래 NavigationBar 스타일 그대로 사용
        NavigationBar(title: title, action: leftAction, buttonImageString: leftButtonImageString)
            // 오른쪽에 메뉴 버튼을 오버레이로 추가 (NavigationBar의 기존 패딩을 그대로 따름)
            .overlay(
                HStack {
                    Spacer()
                    CircularButton(action: {
                        withAnimation {
                            isMenuShown.toggle()
                        }
                    }, buttonImageString: "ellipsis")
                    .padding(.trailing, 28)
                }
            )
            // 메뉴 팝업도 오버레이로 추가하여, 메뉴 버튼 바로 아래쪽에 위치하도록 함
            .overlay(
                Group {
                    if isMenuShown {
                        NavigationMenuPopup(reportAction: {
                            reportAction()
                            withAnimation { isMenuShown = false }
                        }, blockAction: {
                            blockAction()
                            withAnimation { isMenuShown = false }
                        })
                        // 팝업의 위치는 메뉴 버튼을 기준으로 적절하게 오프셋 조정
                        .offset(x: 0, y: 40)
                    }
                },
                alignment: .topTrailing
            )
    }
}
