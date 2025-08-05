//
//  UserInfoModalView.swift
//  Celestoria
//
//  Created by Seyoung Park on 8/2/25.
//

import SwiftUI
import Foundation
import os

struct UserInfoModalView: View {
    let userId: UUID
    let isOwnGalaxy: Bool
    let onAddMemory: () -> Void
    let diContainer: DIContainer
    @StateObject private var viewModel: UserInfoModalViewModel
    
    init(userId: UUID, isOwnGalaxy: Bool, onAddMemory: @escaping () -> Void, diContainer: DIContainer) {
        self.userId = userId
        self.isOwnGalaxy = isOwnGalaxy
        self.onAddMemory = onAddMemory
        self.diContainer = diContainer
        _viewModel = StateObject(wrappedValue: diContainer.makeUserInfoModalViewModel(userId: userId))
    }
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            
            if let profile = viewModel.userProfile {
                VStack(spacing: 0) {
                    profileContentView(profile: profile)
                }
                .modifier(ModalStyleModifier())
                .padding(.horizontal, viewModel.isExpanded ? 0 : 28)
                .scaleEffect(viewModel.isExpanded ? 1.0 : 1.0)
                .frame(maxWidth: .infinity, maxHeight: viewModel.isExpanded ? .infinity : 120)
                .frame(height: viewModel.isExpanded ? UIScreen.main.bounds.height - 52 : 120)
                .padding(.bottom, viewModel.isExpanded ? 0 : 30)
                .offset(y: viewModel.dragOffset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            viewModel.handleDragChanged(value)
                        }
                        .onEnded { value in
                            viewModel.handleDragEnded(value)
                        }
                )
                .onTapGesture {
                    if viewModel.isExpanded {
                        viewModel.closeModal()
                    }
                }
                
                // Add memory button
                if isOwnGalaxy {
                    AddMemoryButton(onAddMemory: onAddMemory, isExpanded: viewModel.isExpanded)
                }
                
            } else if viewModel.isLoading {
                LoadingView()
                    .modifier(ModalStyleModifier())
                    .padding(.horizontal, 20)
            } else {
                // Empty state or error state
                EmptyProfileView()
                    .modifier(ModalStyleModifier())
                    .padding(.horizontal, 20)
            }
        }
        .onAppear {
            // 뷰가 나타날 때마다 프로필 데이터 새로고침
            viewModel.refreshProfileData()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            // 앱이 foreground로 돌아올 때 프로필 데이터 새로고침
            viewModel.refreshProfileData()
        }
    }
    
    // MARK: - Profile Content View
    private func profileContentView(profile: UserProfile) -> some View {
        VStack(spacing: 0) {
            // Close button for expanded state
            if viewModel.isExpanded {
                CloseButtonHeader {
                    viewModel.closeModal()
                }
            }
            
            if viewModel.isExpanded {
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
                            viewModel: viewModel,
                            profile: profile
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


