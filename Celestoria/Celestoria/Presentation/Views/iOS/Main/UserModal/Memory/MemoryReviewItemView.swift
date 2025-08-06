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
                    // Real thumbnail from server
                    AsyncImage(url: URL(string: thumbnailURL)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        // Placeholder while loading
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
                    }
                    .frame(width: UIScreen.main.bounds.width * 0.4, height: UIScreen.main.bounds.height * 0.1)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    // Fallback placeholder
                    RoundedRectangle(cornerRadius: 12)
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
                        .frame(width: 120, height: 80)
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
                
                HStack(spacing: 16) {
                    // comment, like
                    HStack(spacing: 4) {
                        Image("commentWhiteIcon")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 14, height: 14)
                        
                        Text("0")
                            .fontStyle(Fonts.caption1)
                            .foregroundStyle(Colors.NebulaWhite)
                    }
                    
                    HStack(spacing: 4) {
                        Image("likeWhiteIcon")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 14, height: 14)
                        
                        Text("0")
                            .fontStyle(Fonts.caption1)
                            .foregroundStyle(Colors.NebulaWhite)
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
    }
}
