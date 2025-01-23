import SwiftUI
import os
import AVKit

struct MemoryDetailView: View {
    let memory: Memory
    @Environment(\.dismiss) private var dismiss
    
    init(memory: Memory) {
        self.memory = memory
        print("[DEBUG] MemoryDetailView init with id=\(memory.id), title=\(memory.title), videoURL=\(memory.videoURL ?? "nil")")
    }
    
    var body: some View {
        GradientBorderContainer {
            VStack {
                NavigationBar(
                    title: "Memory Detail",
                    buttonImageString: "xmark"
                ) {
                    dismiss()
                }
                
                videoPlayerSection
                    .frame(height: 300)
                
                Text(memory.title)
                    .foregroundColor(.white)
                
                Text(memory.note)
                    .foregroundColor(.white)
                
                Spacer()
            }
        }
        .onAppear {
            // onAppear 시점에도 log
            print("[DEBUG] MemoryDetailView onAppear() - memory.id=\(memory.id)")
        }
    }

    @ViewBuilder
    private var videoPlayerSection: some View {
        if let urlString = memory.videoURL,
           let url = URL(string: urlString) {
            // 1) 실제로 URLSession으로 이 url 접근이 가능한지 확인 (비동기)
            VideoURLDebugLogger(url: url)

            // 2) AVPlayerViewController로 재생
            CelestoriaVideoPlayerView(videoURL: url)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.3))
                Text("No Video")
                    .foregroundColor(.white.opacity(0.8))
            }
        }
    }
}

struct VideoURLDebugLogger: View {
    let url: URL

    var body: some View {
        Color.clear
            .onAppear {
                Task {
                    do {
                        print("🌀 [DEBUG] Testing video URL: \(url)")
                        let (data, response) = try await URLSession.shared.data(from: url)
                        if let httpResponse = response as? HTTPURLResponse {
                            print("✅ [DEBUG] HTTP Status: \(httpResponse.statusCode), data size: \(data.count) bytes")
                        } else {
                            print("✅ [DEBUG] Received data of size: \(data.count)")
                        }
                    } catch {
                        print("❌ [DEBUG] Failed to load data from URL=\(url). Error: \(error.localizedDescription)")
                    }
                }
            }
    }
}
