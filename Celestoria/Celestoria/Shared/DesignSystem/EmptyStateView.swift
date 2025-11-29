//
//  EmptyStateView.swift
//  Celestoria
//
//  Created by Assistant on 1/28/25.
//

import SwiftUI

/// 통일된 빈 상태 뷰 컴포넌트
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let iconSize: CGFloat
    let iconColor: Color
    
    init(
        icon: String,
        title: String,
        message: String,
        iconSize: CGFloat = 48,
        iconColor: Color = Colors.NebulaWhite.opacity(0.3)
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.iconSize = iconSize
        self.iconColor = iconColor
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: icon)
                .font(.system(size: iconSize))
                .foregroundColor(iconColor)
            
            Text(title)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(Colors.NebulaWhite.opacity(0.5))
            
            Text(message)
                .font(.system(size: 14))
                .foregroundColor(Colors.NebulaWhite.opacity(0.3))
                .multilineTextAlignment(.center)
                .lineLimit(nil)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(40)
    }
}

/// 통일된 로딩 뷰 컴포넌트
struct UnifiedLoadingView: View {
    let title: String
    let subtitle: String?
    
    init(title: String, subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(1.5)
                .tint(Colors.NebulaWhite.opacity(0.5))
            
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(Colors.NebulaWhite.opacity(0.5))
                .padding(.top, 8)
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(Colors.NebulaWhite.opacity(0.3))
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

