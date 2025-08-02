//
//  UserInfoModalView.swift
//  Celestoria
//
//  Created by Seyoung Park on 8/2/25.
//

import SwiftUI
import Foundation

struct UserInfoModalView: View {
    let userId: UUID
    let isOwnGalaxy: Bool
    let onAddMemory: () -> Void
    let diContainer: DIContainer
    @StateObject private var viewModel: UserInfoModalViewModel
    @State private var isExpanded = false
    @State private var dragOffset: CGFloat = 0
    
    init(userId: UUID, isOwnGalaxy: Bool, onAddMemory: @escaping () -> Void, diContainer: DIContainer) {
        self.userId = userId
        self.isOwnGalaxy = isOwnGalaxy
        self.onAddMemory = onAddMemory
        self.diContainer = diContainer
        _viewModel = StateObject(wrappedValue: diContainer.makeUserInfoModalViewModel(userId: userId))
    }
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            if isExpanded {
                Colors.BackgroundBlack
                    .ignoresSafeArea()
                    .transition(.opacity)
            }
            
            if let profile = viewModel.userProfile {
                VStack(spacing: 0) {
                    profileContentView(profile: profile)
                }
                .modifier(ModalStyleModifier())
                .padding(.horizontal, isExpanded ? 0 : 28)
                .scaleEffect(isExpanded ? 1.0 : 1.0)
                .frame(maxWidth: .infinity, maxHeight: isExpanded ? .infinity : 120)
                .frame(height: isExpanded ? UIScreen.main.bounds.height - 100 : nil)
                .offset(y: dragOffset)
                .ignoresSafeArea(.all, edges: isExpanded ? .bottom : [])
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            if value.translation.height < 0 {
                                dragOffset = value.translation.height * 0.3
                            }
                        }
                        .onEnded { value in
                            if value.translation.height < -60 {
                                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                    isExpanded = true
                                    dragOffset = 0
                                }
                            } else {
                                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                    dragOffset = 0
                                }
                            }
                        }
                )
                .onTapGesture {
                    if isExpanded {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            isExpanded = false
                        }
                    }
                }
                
                // Add memory button
                if isOwnGalaxy {
                    AddMemoryButton(onAddMemory: onAddMemory, isExpanded: isExpanded)
                }
                
            } else {
                LoadingView()
                    .modifier(ModalStyleModifier())
                    .padding(.horizontal, 20)
            }
        }
    }
    
    // MARK: - Profile Content View
    private func profileContentView(profile: UserProfile) -> some View {
        VStack(spacing: 0) {
            // Close button for expanded state
            if isExpanded {
                CloseButtonHeader {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        isExpanded = false
                    }
                }
            }
            
            if isExpanded {
                ScrollView {
                    VStack(spacing: 0) {
                        Spacer()
                            .frame(height: 20)
                        
                        ProfileHeaderView(profile: profile)
                        
                        Spacer()
                            .frame(height: 16)
                        
                        StatsView(
                            memoryCount: viewModel.memoryCount,
                            commentCount: viewModel.commentCount,
                            likeCount: viewModel.likeCount
                        )
                        
                        Spacer()
                            .frame(height: 20)
                        
                        UserInfoModalExpandedContent(
                            profile: profile,
                            memoryCount: viewModel.memoryCount,
                            commentCount: viewModel.commentCount,
                            likeCount: viewModel.likeCount
                        )
                        
                        Spacer()
                            .frame(height: 0)
                    }
                }
            } else {
                Spacer()
                    .frame(height: 14)
                
                ProfileHeaderView(profile: profile)
                
                Spacer()
                    .frame(height: 16)
                
                StatsView(
                    memoryCount: viewModel.memoryCount,
                    commentCount: viewModel.commentCount,
                    likeCount: viewModel.likeCount
                )
                
                Spacer()
                    .frame(height: 20)
            }
        }
        .frame(maxWidth: .infinity)
    }
}


