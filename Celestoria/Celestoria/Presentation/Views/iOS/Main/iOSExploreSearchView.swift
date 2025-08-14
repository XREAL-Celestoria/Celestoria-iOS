//
//  ExploreSearchView.swift
//  Celestoria
//
//  Created by AI Assistant on 8/12/25.
//

import SwiftUI
import Supabase

struct iOSExploreSearchView: View {
    @ObservedObject var viewModel: ExploreViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isSearchFocused: Bool
    let onClose: (() -> Void)?
    @State private var searchHistory: [String] = []
    @State private var showingSuggestions: Bool = false
    @State private var hasSubmittedSearch: Bool = false
    @State private var isLoadingSuggestions: Bool = false
    @State private var showingGalaxyFromSearch: Bool = false
    @State private var showingOwnGalaxyPopup = false
    private let historyKey = "ExploreSearchHistory"
    
    private enum Phase { 
        case history, suggest, result, empty 
    }
    
    private var phase: Phase {
        if viewModel.searchText.isEmpty {
            return showingSuggestions ? .suggest : .history
        }
        if hasSubmittedSearch {
            // 검색어가 있고 제출된 상태라면 결과 또는 빈 결과 표시
            return viewModel.exploreUsers.isEmpty ? .empty : .result
        }
        // 검색어가 있지만 아직 제출되지 않은 상태라면 추천 표시
        return .suggest
    }
    
    var body: some View {
        ZStack {
            Colors.backgroundMain.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Search Bar
                HStack(spacing: 6) {
                    HStack(spacing: 8) {
                        Image("searchIcon")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 18, height: 18)
                            .foregroundStyle(Colors.Placeholder)
                        
                        TextField("Search...", text: $viewModel.searchText)
                            .font(.system(size: 18))
                            .foregroundStyle(Colors.NebulaWhite)
                            .focused($isSearchFocused)
                            .onChange(of: viewModel.searchText) { _, newValue in
                                // 최신검색어를 누른 후에는 onChange에서 hasSubmittedSearch를 false로 설정하지 않음
                                if !hasSubmittedSearch {
                                    if newValue.isEmpty {
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            showingSuggestions = false
                                            hasSubmittedSearch = false
                                        }
                                    } else {
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            showingSuggestions = true
                                            hasSubmittedSearch = false
                                        }
                                    }
                                    Task { await viewModel.onChangeSearchText() }
                                }
                            }
                            .onSubmit {
                                addHistory(viewModel.searchText)
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    hasSubmittedSearch = true
                                    showingSuggestions = false
                                }
                            }
                        
                        if !viewModel.searchText.isEmpty {
                            Button(action: {
                                viewModel.searchText = ""
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    showingSuggestions = false
                                    hasSubmittedSearch = false
                                }
                            }) {
                                Image("searchXIcon")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 18, height: 18)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 30)
                            .stroke(LinearGradient.SearchUsercardBG, lineWidth: 2)
                    )
                    .background(
                        RoundedRectangle(cornerRadius: 30)
                            .fill(Colors.ProfileNamebox)
                    )
                    
                    Button(action: {
                        if let onClose { onClose() } else { dismiss() }
                    }) {
                        HStack(alignment: .center) {
                            Spacer().frame(width: 10)
                            
                            Text("Cancel")
                                .fontStyle(Fonts.subheadline)
                                .foregroundStyle(LinearGradient.MainGradient)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 28)
                
                // All Views with Opacity Control
                ZStack {
                    // History View
                    ScrollView {
                        LazyVStack(spacing: 20) {
                            ForEach(searchHistory, id: \.self) { term in
                                HStack {
                                    Text(term)
                                        .fontStyle(Fonts.body1)
                                        .foregroundStyle(Colors.NebulaWhite)
                                        .onTapGesture {
                                            viewModel.searchText = term
                                            withAnimation(.easeInOut(duration: 0.3)) {
                                                hasSubmittedSearch = true
                                                showingSuggestions = false
                                            }
                                            Task { 
                                                // 검색 결과를 명시적으로 가져오기
                                                await viewModel.fetchExploreUsers()
                                            }
                                        }
                                    Spacer()
                                    Button(action: { removeHistory(term) }) {
                                        Image("searchXMark")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 18, height: 18)
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                        }
                        .padding(.bottom, 100) // 하단 여백 추가
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .opacity(phase == .history ? 1 : 0)
                    .animation(.easeInOut(duration: 0.3), value: phase)
                    
                    // Suggest View
                    ScrollView {
                        LazyVStack(spacing: 20) {
                            if viewModel.searchText.isEmpty {
                                // 포커싱만 되었을 때 기본 추천 유저들 표시
                                // 추천 유저들 표시
                                ForEach(viewModel.popularUsers.prefix(5), id: \.profile.userId) { user in
                                    if let card = viewModel.getCardItem(by: user.profile.userId) {
                                        Button(action: {
                                            if viewModel.isCurrentUser(user) {
                                                // 자기 자신의 갤럭시를 누를 때
                                                showingOwnGalaxyPopup = true
                                            } else {
                                                // 다른 유저의 갤럭시를 누를 때
                                                addHistory(user.profile.name)
                                                viewModel.selectedUser = user
                                                showingGalaxyFromSearch = true
                                            }
                                        }) { 
                                            SuggestionRow(card: card, user: user) 
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                            } else {
                                // 검색어가 있을 때 작은 추천 뷰 표시
                                ForEach(viewModel.exploreUsers, id: \.profile.userId) { user in
                                    if let card = viewModel.getCardItem(by: user.profile.userId) {
                                        Button(action: {
                                            if viewModel.isCurrentUser(user) {
                                                // 자기 자신의 갤럭시를 누를 때
                                                showingOwnGalaxyPopup = true
                                            } else {
                                                // 다른 유저의 갤럭시를 누를 때
                                                addHistory(viewModel.searchText)
                                                viewModel.selectedUser = user
                                                showingGalaxyFromSearch = true
                                            }
                                        }) { 
                                            SuggestionRow(card: card, user: user) 
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 100) // 하단 여백 추가
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .opacity(phase == .suggest ? 1 : 0)
                    .animation(.easeInOut(duration: 0.3), value: phase)
                    
                    // Result View
                    ScrollView {
                        LazyVStack(spacing: 24) {
                            Spacer().frame(height: 4)
                            ForEach(viewModel.exploreUsers, id: \.profile.userId) { user in
                                if let card = viewModel.getCardItem(by: user.profile.userId) {
                                    Button(action: {
                                        if viewModel.isCurrentUser(user) {
                                            // 자기 자신의 갤럭시를 누를 때
                                            showingOwnGalaxyPopup = true
                                        } else {
                                            // 다른 유저의 갤럭시를 누를 때
                                            addHistory(viewModel.searchText)
                                            viewModel.selectedUser = user
                                            showingGalaxyFromSearch = true
                                        }
                                    }) { 
                                        LargeResultRow(card: card, user: user) 
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 100) // 하단 여백 추가
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .opacity(phase == .result ? 1 : 0)
                    .animation(.easeInOut(duration: 0.3), value: phase)
                    
                    // Empty View
                    VStack(spacing: 16) {
                        Image("searchEmptyIcon")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 120, height: 120)
                            .foregroundStyle(Colors.Placeholder)
                        Text("We couldn't find a match")
                            .fontStyle(Fonts.title2)
                            .foregroundStyle(Colors.NebulaWhite)
                        
                        Text("Try adjusting your search\nto find what you are looking for!")
                            .fontStyle(Fonts.body1)
                            .foregroundStyle(Colors.NebulaWhite)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.vertical, 40)
                    .opacity(phase == .empty ? 1 : 0)
                    .animation(.easeInOut(duration: 0.3), value: phase)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
        }
        .onAppear {
            loadHistory()
            // 초기 상태 설정 - 처음에는 검색 히스토리 표시
            showingSuggestions = false
            hasSubmittedSearch = false
            isLoadingSuggestions = false
            
            // 검색 결과 초기화 및 모스트 스탈스 데이터 리프레시
            Task {
                viewModel.clearSearchResults()
                await viewModel.refreshMostStarsData()
            }
        }
        .onDisappear {
            // 서치뷰가 사라질 때 검색 결과 완전 정리
            viewModel.clearSearchResults()
            
            // 모스트 스탈스 데이터 복원
            Task {
                await viewModel.refreshMostStarsData()
            }
        }
        .onChange(of: isSearchFocused) { _, isFocused in
            if isFocused {
                // 포커싱 시 즉시 로딩 상태로 전환
                isLoadingSuggestions = true
                
                withAnimation(.easeInOut(duration: 0.3)) {
                    showingSuggestions = true
                    hasSubmittedSearch = false
                }
                
                // 1초 후에 로딩 완료
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isLoadingSuggestions = false
                    }
                }
            } else {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showingSuggestions = false
                    isLoadingSuggestions = false
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        // 키보드가 올라와도 하단이 잘리지 않도록 여유 inset 추가
        .safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: 24)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        // Present Galaxy directly from Search
        .fullScreenCover(isPresented: $showingGalaxyFromSearch) {
            if let selected = viewModel.selectedUser {
                iOS3DGalaxyView(diContainer: viewModel.diContainer, targetUserId: selected.profile.userId)
                    .toolbar(.hidden, for: .navigationBar)
            }
        }
        .overlay(
            Group {
                if isLoadingSuggestions && phase == .suggest {
                    VStack(spacing: 16) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Colors.NebulaWhite))
                            .scaleEffect(1.2)
                        Text("Loading Suggestions...")
                            .fontStyle(Fonts.caption1)
                            .foregroundStyle(Colors.Placeholder)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Colors.BackgroundBlack.opacity(0.8))
                }
                
                if showingOwnGalaxyPopup {
                    iOSConfirmationPopupView(
                        title: "Your Own Galaxy",
                        message: "This is your own galaxy. You can view it from the main screen.",
                        style: .singleButton(title: "OK"),
                        onCancel: { 
                            withAnimation(.easeInOut(duration: 0.4)) {
                                showingOwnGalaxyPopup = false
                            }
                        },
                        onConfirm: { 
                            withAnimation(.easeInOut(duration: 0.4)) {
                                showingOwnGalaxyPopup = false
                            }
                        }
                    )
                }
            }
        )
    }
    
    // MARK: - Private Methods
    private func loadHistory() {
        if let data = UserDefaults.standard.array(forKey: historyKey) as? [String] {
            searchHistory = data
        }
    }
    
    private func addHistory(_ term: String) {
        let trimmed = term.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        searchHistory.removeAll { $0.caseInsensitiveCompare(trimmed) == .orderedSame }
        searchHistory.insert(trimmed, at: 0)
        if searchHistory.count > 10 { 
            searchHistory = Array(searchHistory.prefix(10)) 
        }
        UserDefaults.standard.set(searchHistory, forKey: historyKey)
    }
    
    private func removeHistory(_ term: String) {
        searchHistory.removeAll { $0 == term }
        UserDefaults.standard.set(searchHistory, forKey: historyKey)
    }
}

// MARK: - Suggestion Row (compact)
private struct SuggestionRow: View {
    let card: ExploreUserCardItem
    let user: ExploreUser
    
    var body: some View {
        HStack(spacing: 8) {
            // Profile Image
            ProfileImageView(
                profile: user.profile,
                size: 32
            )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(card.userName)
                    .fontStyle(Fonts.subheadline)
                    .foregroundStyle(Colors.NebulaWhite)
                    .lineLimit(1)
                Text("\(card.memoryStars) Memory Stars")
                    .fontStyle(Fonts.caption2)
                    .foregroundStyle(Colors.Placeholder)
                    .lineLimit(1)
            }
    
            Spacer()
        }
    }
}

// MARK: - Large Result Row 
private struct LargeResultRow: View {
    let card: ExploreUserCardItem
    let user: ExploreUser
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                Image(card.imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: UIScreen.main.bounds.width * 0.61,
                           height: UIScreen.main.bounds.width * 0.61 * (152.0 / 240.0))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(LinearGradient.SearchUsercardBG, lineWidth: 5)
                    )
                
                VStack(alignment: .leading, spacing: 8) {
                    ProfileImageView(
                        profile: user.profile,
                        size: 32
                    )
                    
                    Text(card.userName)
                        .fontStyle(Fonts.subheadline)
                        .foregroundStyle(Colors.NebulaWhite)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    Text("\(card.memoryStars) Memory Stars")
                        .fontStyle(Fonts.caption2)
                        .foregroundStyle(Colors.Placeholder)
                        .lineLimit(1)
                }
                
                Spacer(minLength: 0)
            }
        }
    }
}
