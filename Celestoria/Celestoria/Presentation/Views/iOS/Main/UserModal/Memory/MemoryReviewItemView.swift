//
//  MemoryReviewItemView.swift
//  Celestoria-iOS
//
//  Created by Seyoung Park on 8/7/25.
//

import SwiftUI

// MARK: - Memory List Item View
struct MemoryListItemView: View {
    let memory: Memory
    let viewModel: UserInfoModalViewModel
    @EnvironmentObject var appState: AppState
    
    private var daysAgo: Int {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.day], from: memory.createdAt, to: now)
        return components.day ?? 0
    }
    
    private var formattedDuration: String {
        // For now, return a placeholder duration
        // In the future, this could be extracted from video metadata
        return "0:30"
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Thumbnail with duration overlay
            ZStack(alignment: .bottomTrailing) {
                if let thumbnailURL = memory.thumbnailURL {
                    // Cached thumbnail with in-image progress indicator
                    let thumbnailHeight = UIScreen.main.bounds.height * 0.1
                    let thumbnailWidth = thumbnailHeight * (150.0 / 95.0)
                    ZStack {
                        // Gradient placeholder background
                        RoundedRectangle(cornerRadius: 20)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(red: 0.2, green: 0.3, blue: 0.5),
                                        Color(red: 0.1, green: 0.15, blue: 0.25)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )

                        // Cached image loader (shows ProgressView while loading)
                        CachedAsyncImage(urlString: thumbnailURL, size: thumbnailHeight)
                            .frame(width: thumbnailWidth, height: thumbnailHeight)
                            .clipped()
                    }
                    .frame(width: thumbnailWidth, height: thumbnailHeight)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                } else {
                    // Fallback placeholder
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 0.2, green: 0.3, blue: 0.5),
                                    Color(red: 0.1, green: 0.15, blue: 0.25)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: UIScreen.main.bounds.height * 0.1 * (150.0 / 95.0), height: UIScreen.main.bounds.height * 0.1)
                        .overlay(
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white.opacity(0.8))
                        )
                }
                
                // Duration badge
                Text(formattedDuration)
                    .fontStyle(Fonts.caption2)
                    .foregroundColor(Colors.NebulaWhite)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.black.opacity(0.5))
                    )
                    .padding(.trailing, 6)
                    .padding(.bottom, 6)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        LinearGradient.SearchUsercardBG
                        ,
                        lineWidth: 3
                    )
            )
            
            // Content
            VStack(alignment: .leading, spacing: 8) {
                Text(memory.title)
                    .fontStyle(Fonts.subheadline)
                    .foregroundColor(Colors.NebulaWhite)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                HStack{
                    Text("\(daysAgo)d ago")
                        .fontStyle(Fonts.caption1)
                        .foregroundStyle(Colors.Placeholder)
                    
                    Spacer()
                }
                
                // HStack(spacing: 16) {
                //     // comment, like (temporarily disabled for App Store submission)
                //     HStack(spacing: 4) {
                //         Image("commentWhiteIcon")
                //             .resizable()
                //             .scaledToFit()
                //             .frame(width: 14, height: 14)
                //         
                //         Text("0")
                //             .fontStyle(Fonts.caption1)
                //             .foregroundStyle(Colors.NebulaWhite)
                //     }
                //     
                //     HStack(spacing: 4) {
                //         Image("likeWhiteIcon")
                //             .resizable()
                //             .scaledToFit()
                //             .frame(width: 14, height: 14)
                //         
                //         Text("0")
                //             .fontStyle(Fonts.caption1)
                //             .foregroundStyle(Colors.NebulaWhite)
                //     }
                // }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .contentShape(Rectangle()) // 전체 영역을 탭 가능하게 만듦
        .onTapGesture {
            // ViewModel을 통해 메모리 선택 처리
            viewModel.selectMemory(memory)
        }
    }
}
