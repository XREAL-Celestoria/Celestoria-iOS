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
    let onAddMemory: (() -> Void)?
    let onSelectMemory: ((Memory) -> Void)?
    let diContainer: DIContainer
    @StateObject private var viewModel: UserInfoModalViewModel
    @State private var selectedTab: ProfileTab = .memories
    @State private var selectedCategories: Set<MemoriesTabContentView.MemoryCategory> = []
    @State private var showCategoryFilter = false
    @EnvironmentObject var appState: AppState
    
    init(userId: UUID, isOwnGalaxy: Bool, onAddMemory: (() -> Void)?, onSelectMemory: ((Memory) -> Void)? = nil, diContainer: DIContainer) {
        self.userId = userId
        self.isOwnGalaxy = isOwnGalaxy
        self.onAddMemory = onAddMemory
        self.onSelectMemory = onSelectMemory
        self.diContainer = diContainer
        _viewModel = StateObject(wrappedValue: diContainer.makeUserInfoModalViewModel(userId: userId))
    }
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            
            if let profile = viewModel.userProfile {
                VStack(spacing: 0) {
                    profileContentView(profile: profile)
                }
                .modifier(ModalStyleModifier(cornerRadius: 24, isExpanded: viewModel.isExpanded))
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
                    if !viewModel.isExpanded {
                        viewModel.expandModal()
                    }
                }
                
                // Add memory button (축소 상태에서만 외부에 표시, onAddMemory가 있을 때만)
                if isOwnGalaxy && !viewModel.isExpanded && onAddMemory != nil {
                    AddMemoryButton(onAddMemory: onAddMemory, isExpanded: viewModel.isExpanded)
                }
                
            } else if viewModel.isLoading {
                LoadingView()
                    .modifier(ModalStyleModifier(isExpanded: viewModel.isExpanded))
                    .padding(.horizontal, 20)
            } else {
                // Empty state or error state
                EmptyProfileView()
                    .modifier(ModalStyleModifier(isExpanded: viewModel.isExpanded))
                    .padding(.horizontal, 20)
            }
            
            // Category Filter Button Overlay (Memories 탭에서만 표시)
            if viewModel.isExpanded && selectedTab == .memories {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        CategoryFilterButton(
                            selectedCategories: $selectedCategories,
                            showCategoryFilter: $showCategoryFilter
                        )
                        Spacer()
                            .frame(width: 24)
                    }
                    Spacer()
                        .frame(height: 56)
                }
                .onTapGesture {
                    // 필터 버튼 외부 클릭 시 필터 닫기
                    if showCategoryFilter {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showCategoryFilter = false
                        }
                    }
                }
            }
        }
        .onAppear {
            Task { await viewModel.refreshProfileData() }
            selectedTab = .memories
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            Task { await viewModel.refreshProfileData() }
        }
    }
    
    // MARK: - Profile Content View
    private func profileContentView(profile: UserProfile) -> some View {
        ZStack {
            VStack(spacing: 0) {
                if viewModel.isExpanded {
                    ScrollView {
                        VStack(spacing: 0) {
                            
                            ZStack {
                                ThumbnailSectionView(profile: profile)
                                if isOwnGalaxy && onAddMemory != nil {
                                    VStack {
                                        HStack {
                                            Spacer()
                                            AddMemoryButton(onAddMemory: onAddMemory, isExpanded: viewModel.isExpanded)
                                        }
                                        Spacer()
                                    }
                                }
                            }
                            
                            VStack(spacing: 0) {
                                Spacer()
                                    .frame(height: 24)
                                
                                ProfileHeaderStatsView(
                                    profile: profile,
                                    memoryCount: viewModel.memoryCount,
                                    commentCount: viewModel.commentCount,
                                    likeCount: viewModel.likeCount,
                                    showEditButton: isOwnGalaxy, 
                                    isExpanded: viewModel.isExpanded,
                                    selectedTab: selectedTab,
                                    onEditTap: {
                                        // 프로필 편집 버튼
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            viewModel.closeModal()
                                        }
                                        
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                            appState.shouldNavigateToProfileEdit = true
                                        }
                                    },
                                    onTabSelected: { tab in
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            selectedTab = tab
                                        }
                                    }
                                )
                                
                                Spacer()
                                    .frame(height: 20)
                            }
                            .background(Colors.ConsoleSignOutBG)
                            
                            TabContentView(selectedTab: $selectedTab, viewModel: viewModel, selectedCategories: selectedCategories)
                                .frame(minHeight: 400)
                                .environmentObject(appState)
                                .onReceive(viewModel.$selectedMemory) { memory in
                                    if let memory = memory {
                                        if let onSelectMemory = onSelectMemory {
                                            // 부모에게 위임 (예: 다른 유저의 갤럭시 내부에서 로컬 프리젠트)
                                            onSelectMemory(memory)
                                        } else {
                                            // 기본: AppState 기반 네비게이션 (메인 컨테이너 경로)
                                            appState.selectedMemoryForDetail = memory
                                            appState.shouldNavigateToMemoryDetail = true
                                        }
                                        // 선택 상태 리셋
                                        viewModel.selectedMemory = nil
                                    }
                                }
                            
                            
                            Spacer()
                                .frame(height: 50)
                            
                        }
                        .scrollBounceBehavior(.basedOnSize)
                        .scrollIndicators(.hidden)
                    }
                } else {
                    // 축소
                    Spacer()
                        .frame(height: 14)
                    
                    ProfileHeaderStatsView(
                        profile: profile,
                        memoryCount: viewModel.memoryCount,
                        commentCount: viewModel.commentCount,
                        likeCount: viewModel.likeCount,
                        isExpanded: viewModel.isExpanded,
                        selectedTab: selectedTab
                    )
                    
                    Spacer()
                        .frame(height: 20)
                }
            }
            if viewModel.isExpanded {
                VStack(alignment: .leading) {
                    // 상단 전체 드래그 영역 (투명한 영역)
                    HStack {
                        Rectangle()
                            .fill(Color.clear)
                            .frame(width: UIScreen.main.bounds.size.width - 100 ,height: 80)
                            .contentShape(Rectangle())
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        if value.translation.height > 0 {
                                            viewModel.dragOffset = value.translation.height * 0.5
                                        }
                                    }
                                    .onEnded { value in
                                        if value.translation.height > 50 {
                                            viewModel.closeModal()
                                        } else {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                                viewModel.dragOffset = 0
                                            }
                                        }
                                    }
                            )
                        Spacer()
                    }
                    .overlay(
                        VStack {
                            Spacer()
                                .frame(height: 16)
                            RoundedRectangle(cornerRadius: 2.5)
                                .fill(Colors.NebulaWhite.opacity(0.7))
                                .frame(width: 36, height: 5)
                            Spacer()
                        }
                    )
                    
                    Spacer()
                }
            }
        }
        .frame(maxWidth: .infinity)
        .animation(.easeInOut(duration: 0.3), value: viewModel.isExpanded)
    }
}


