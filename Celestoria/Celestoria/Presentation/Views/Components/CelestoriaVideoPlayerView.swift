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
        let player = AVPlayer(url: videoURL)
        let playerViewController = AVPlayerViewController()
        playerViewController.player = player
        
        // 전체 화면 자동 전환 설정
        playerViewController.entersFullScreenWhenPlaybackBegins = true
        
        return playerViewController
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        // 업데이트 필요 없음
    }
}
