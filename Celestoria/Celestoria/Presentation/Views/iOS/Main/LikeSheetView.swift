//
//  LikeSheetView.swift
//  Celestoria
//
//  Created by Seyoung Park on 8/7/25.
//

import SwiftUI

struct LikeSheetView: View {
    let memory: Memory
    let diContainer: DIContainer
    @Environment(\.dismiss) private var dismiss
    
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
    @State private var likedUsers: [(profile: UserProfile?, likedAt: Date)] = []
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                Spacer().frame(height: 16)
                // Handle
                HStack { Spacer(); RoundedRectangle(cornerRadius: 2.5).fill(Colors.NebulaWhite.opacity(0.3)).frame(width: 36, height: 5); Spacer() }
                
                // Title
                HStack {
                    Text("Like")
                        .fontStyle(Fonts.callout)
                        .foregroundColor(Colors.NebulaWhite)
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 30)
                
                Spacer().frame(height: 24)
                
                if isLoading {
                    Spacer()
                    ProgressView().progressViewStyle(CircularProgressViewStyle(tint: Colors.NebulaWhite))
                    Spacer()
                } else if likedUsers.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image("Like-on")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 48, height: 48)
                        
                        Text("No likes yet")
                            .fontStyle(Fonts.subheadline)
                            .foregroundColor(Colors.NebulaWhite)
                        
                        Text("Be the first to like!")
                            .fontStyle(Fonts.caption1)
                            .foregroundColor(Colors.Placeholder)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 28) {
                            ForEach(likedUsers.indices, id: \.self) { index in
                                let item = likedUsers[index]
                                LikeUserRow(profile: item.profile, likedAt: item.likedAt)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 24)
                    }
                }
            }
            .background(Colors.BackgroundBlack)
            .navigationBarHidden(true)
            .task { await loadLikes() }
        }
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: { Text(errorMessage ?? "") }
    }
    
    private func loadLikes() async {
        isLoading = true
        defer { isLoading = false }
        do {
            // Fetch likes for memory
            let likes: [Like] = try await diContainer.memoryRepository.fetchLikes(for: memory.id)
            var result: [(UserProfile?, Date)] = []
            for like in likes {
                let profile = try? await diContainer.profileUseCase.fetchProfileByUserId(userId: like.userId)
                result.append((profile, like.createdAt))
            }
            // sort by newest first
            likedUsers = result.sorted(by: { $0.1 > $1.1 })
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct LikeUserRow: View {
    let profile: UserProfile?
    let likedAt: Date
    
    var body: some View {
        HStack {
            if let profile {
                ProfileImageView(profile: profile, size: 28)
            } else {
                Image("profile_gray")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 28, height: 28)
                    .clipShape(Circle())
            }
            
            Text(profile?.name ?? "User name")
                .fontStyle(Fonts.title3)
                .foregroundStyle(Colors.NebulaWhite)
            
            Text("•").fontStyle(Fonts.callout).foregroundStyle(Colors.NebulaWhite)
            Text(relativeTime(from: likedAt))
                .fontStyle(Fonts.callout)
                .foregroundStyle(Colors.Placeholder)
            
            Spacer()
        }
    }
    
    private func relativeTime(from date: Date) -> String {
        let now = Date()
        let diff = now.timeIntervalSince(date)
        if diff < 60 { return "now" }
        if diff < 3600 { return "\(Int(diff / 60))m" }
        if diff < 86400 { return "\(Int(diff / 3600))h" }
        return "\(Int(diff / 86400))d"
    }
}
