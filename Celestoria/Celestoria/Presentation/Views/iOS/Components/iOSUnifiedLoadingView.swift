
//
//  iOSUnifiedLoadingView.swift
//  Celestoria
//
//  Created by Assistant on 1/28/25.
//

import SwiftUI
import UIKit

struct iOSUnifiedLoadingView: View {
    let title: String
    let subtitle: String?
    @State private var viewAppeared = false
    @State private var shouldShow = false
    
    init(title: String, subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
    }
    
    var body: some View {
        ZStack {
            // 기존 화면 위에 머티리얼 오버레이
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // 커스텀 로딩 애니메이션
                CustomLoadingAnimation()
                    .frame(width: 80, height: 80)
                    .opacity(shouldShow ? 1 : 0)
                    .scaleEffect(shouldShow ? 1 : 0.8)
                    .animation(.easeOut(duration: 0.3), value: shouldShow)
                
                // 타이틀
                Text(title)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .opacity(shouldShow ? 1 : 0)
                    .offset(y: shouldShow ? 0 : 10)
                    .animation(.easeOut(duration: 0.3).delay(0.1), value: shouldShow)
                
                // 서브타이틀 (필요시만)
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .opacity(shouldShow ? 1 : 0)
                        .offset(y: shouldShow ? 0 : 10)
                        .animation(.easeOut(duration: 0.3).delay(0.2), value: shouldShow)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .opacity(viewAppeared ? 1 : 0)
        .animation(.easeInOut(duration: 0.2), value: viewAppeared)
        .onAppear {
            // 뷰가 나타날 때 즉시 표시
            viewAppeared = true
            
            // 약간의 지연 후 애니메이션 시작
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeOut(duration: 0.3)) {
                    shouldShow = true
                }
            }
        }
        .onDisappear {
            // 뷰가 사라질 때 상태 리셋
            viewAppeared = false
            shouldShow = false
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
            
            // 메인 로딩 인디케이터 (무한 회전)
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
            // 즉시 애니메이션 시작
            isAnimating = true
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            // 앱이 활성화될 때 애니메이션 재시작
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
