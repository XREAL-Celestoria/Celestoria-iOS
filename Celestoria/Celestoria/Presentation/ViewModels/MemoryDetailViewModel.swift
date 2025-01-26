//
//  MemoryDetailViewModel.swift
//  Celestoria
//
//  Created by Park Seyoung on 1/27/25.
//

import Foundation
import Combine

@MainActor
final class MemoryDetailViewModel: ObservableObject {
    @Published private(set) var memory: Memory
    @Published var formattedDate: String = ""
    @Published var videoURLStatus: String = ""
    
    private var cancellables = Set<AnyCancellable>()
    
    init(memory: Memory) {
        self.memory = memory
        self.formatDate()
        self.checkVideoURL()
    }
    
    private func formatDate() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd HH:mm"
        formattedDate = formatter.string(from: memory.createdAt)
    }
    
    private func checkVideoURL() {
        guard let urlString = memory.videoURL, let url = URL(string: urlString) else {
            videoURLStatus = "Invalid URL"
            return
        }
        
        Task { [weak self] in
            guard let self = self else { return }
            do {
                let (data, response) = try await URLSession.shared.data(from: url)
                DispatchQueue.main.async {
                    if let httpResponse = response as? HTTPURLResponse {
                        self.videoURLStatus = "HTTP Status: \(httpResponse.statusCode), size: \(data.count) bytes"
                    } else {
                        self.videoURLStatus = "Data size: \(data.count)"
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.videoURLStatus = "Error: \(error.localizedDescription)"
                }
            }
        }
    }

}
