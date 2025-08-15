//
//  MemoryDetailOptionMenuView.swift
//  Celestoria
//
//  Created by AI Assistant on 2025.
//

import SwiftUI

struct MemoryDetailOptionMenuView: View {
    let onReportTap: () -> Void
    let onBlockUserTap: () -> Void
    let onDismiss: () -> Void
    let hasAlreadyReported: Bool
    let optionButtonFrame: CGRect
    
    var body: some View {
        VStack {
            Spacer()
            
            // Report Post Option - 항상 동일하게 표시
            Button(action: onReportTap) {
                HStack(spacing: 12) {
                    Image("report")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 22, height: 22)
                    
                    Text("Report Post")
                        .fontStyle(Fonts.subheadline)
                        .foregroundStyle(Colors.NebulaWhite)
                    
                    Spacer()
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 12)
            }
            
            // Block User Option
            Button(action: onBlockUserTap) {
                HStack(spacing: 12) {
                    Image("block")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 22, height: 22)
                    
                    Text("Block User")
                        .fontStyle(Fonts.subheadline)
                        .foregroundStyle(Colors.NebulaWhite)
                    
                    Spacer()
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 12)
            }
            
            Spacer()
        }
        .frame(width: 164, height: 96)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        Colors.BackgroundBlack.opacity(0.9)
                    )
                
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient.BackgroundPopup
                    )
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .inset(by: 0.75)
                .stroke(Color(red: 0.65, green: 0.91, blue: 1), lineWidth: 1)
        )
        .position(
            x: optionButtonFrame.maxX - 86, // 옵션 버튼 오른쪽 끝에서 메뉴 너비만큼 왼쪽으로
            y: optionButtonFrame.minY + 8   // 옵션 버튼 아래쪽에 메뉴 높이의 절반만큼
        )
        .onTapGesture {
            // 메뉴 외부 터치 시 닫기 방지
        }
    }
}

