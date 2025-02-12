//
//  CelestoriaVideoPlayerView.swift
//  Celestoria
//
//  Created by Minjun Kim on 1/24/25.
//

import SwiftUI
import AVKit

/// AVPlayerViewController를 SwiftUI에서 사용하기 위한 Representable
struct CelestoriaVideoPlayerView: UIViewControllerRepresentable {
    let videoURL: URL

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        // AVPlayer 생성 및 설정
        let player = AVPlayer(url: videoURL)
        let playerViewController = AVPlayerViewController()
        playerViewController.player = player
        
        // 전체화면 모드에 진입하게 하려면 fullScreenCover로 보여주므로,
        // 여기서는 플레이어가 로드되자마자 자동 재생하도록 합니다.
        DispatchQueue.main.async {
            player.play()
        }
        
        return playerViewController
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        // 업데이트 필요 없음
    }
}
