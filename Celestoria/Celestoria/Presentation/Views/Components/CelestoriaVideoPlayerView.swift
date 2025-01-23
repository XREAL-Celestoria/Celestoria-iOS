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
        
        // 3D Video 재생을 위해 필요한 설정이 있다면 여기서 추가
        // ex) playerViewController.entersFullScreenWhenPlaybackBegins = true
        
        return playerViewController
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        // 필요 시, 재생 상태 동기화
    }
}
