
//
//  iOSUnifiedLoadingView.swift
//  Celestoria
//
//  Created by Assistant on 1/28/25.
//

import SwiftUI

struct iOSUnifiedLoadingView: View {
    let title: String
    let subtitle: String?
    
    init(title: String, subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
    }
    
    var body: some View {
        ZStack {
            // 기존 화면 위에 블러 + 투명도 오버레이
            Color.clear
                .background(.ultraThinMaterial)
                .background(Color.black.opacity(0.1))
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // 커스텀 로딩 애니메이션
                CustomLoadingAnimation()
                    .frame(width: 80, height: 80)
                
                // 타이틀
                Text(title)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                // 서브타이틀 (필요시만)
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

// MARK: - 편의 생성자들
extension iOSUnifiedLoadingView {
    
    /// 기본 로딩뷰
    static func basic(title: String = "Loading.") -> iOSUnifiedLoadingView {
        iOSUnifiedLoadingView(title: title)
    }
    
    /// 초기 앱 로딩뷰 (약관동의 후)
    static func appInitializing() -> iOSUnifiedLoadingView {
        iOSUnifiedLoadingView(title: "Initializing.")
    }
    
    /// 업로드 로딩뷰
    static func upload(fileSize: String = "") -> iOSUnifiedLoadingView {
        let subtitle = fileSize.isEmpty ? nil : "Uploading \(fileSize) video file..."
        return iOSUnifiedLoadingView(title: "Uploading.", subtitle: subtitle)
    }
    
    /// 프로필 로딩뷰
    static func profile() -> iOSUnifiedLoadingView {
        iOSUnifiedLoadingView(title: "Loading Profile.")
    }
    
    /// 갤럭시/스타 로딩뷰
    static func stars() -> iOSUnifiedLoadingView {
        iOSUnifiedLoadingView(title: "Loading Stars.")
    }
    
    /// 업로드 진행률 포함 로딩뷰
    static func uploadWithProgress(fileSize: String, progress: Double) -> iOSUnifiedLoadingView {
        let subtitle = fileSize.isEmpty ? 
            "Progress: \(Int(progress * 100))%" : 
            "Uploading \(fileSize) - \(Int(progress * 100))%"
        return iOSUnifiedLoadingView(title: "Uploading.", subtitle: subtitle)
    }
    
    /// 업로드 상태 메시지 포함 로딩뷰
    static func uploadWithStatus(fileSize: String, status: String) -> iOSUnifiedLoadingView {
        let subtitle = status.isEmpty ? "Uploading \(fileSize) video file..." : status
        return iOSUnifiedLoadingView(title: "Uploading.", subtitle: subtitle)
    }
    
    /// 메모리 상세 로딩뷰
    static func memoryDetail() -> iOSUnifiedLoadingView {
        iOSUnifiedLoadingView(title: "Loading Memory.")
    }
    
    /// 썸네일 생성 로딩뷰
    static func thumbnail() -> iOSUnifiedLoadingView {
        iOSUnifiedLoadingView(title: "Generating.")
    }
    
    /// 전체화면 로딩뷰 (미니멀 디자인)
    static func fullscreen(title: String = "Loading.", subtitle: String? = nil) -> iOSUnifiedLoadingView {
        iOSUnifiedLoadingView(title: title, subtitle: subtitle)
    }
}

// MARK: - 커스텀 로딩 애니메이션
struct CustomLoadingAnimation: View {
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // 외곽 원 (회전)
            Circle()
                .stroke(Color.white.opacity(0.2), lineWidth: 2)
                .frame(width: 60, height: 60)
            
            // 내부 원 (회전)
            Circle()
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                .frame(width: 40, height: 40)
            
            // 메인 로딩 인디케이터
            Circle()
                .trim(from: 0, to: 0.3)
                .stroke(
                    LinearGradient(
                        colors: [Color.white, Color.white.opacity(0.3)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
                .frame(width: 60, height: 60)
                .rotationEffect(.degrees(isAnimating ? 360 : 0))
                .animation(
                    .linear(duration: 1.0).repeatForever(autoreverses: false),
                    value: isAnimating
                )
            
            // 중앙 점
            Circle()
                .fill(Color.white.opacity(0.8))
                .frame(width: 8, height: 8)
        }
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - 프리뷰
struct iOSUnifiedLoadingView_Previews: PreviewProvider {
    static var previews: some View {
        iOSUnifiedLoadingView.basic()
    }
}
