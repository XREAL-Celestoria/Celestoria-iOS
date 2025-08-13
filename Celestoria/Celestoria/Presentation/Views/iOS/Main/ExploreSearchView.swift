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
    private let historyKey = "ExploreSearchHistory"
    private enum Phase { case history, suggest, result, empty }
    @State private var didSubmit: Bool = false
    @State private var submittedResults: [ExploreUser] = []
    private var phase: Phase {
        // While focused, never show results – only history/suggest
        if isSearchFocused {
            return viewModel.searchText.isEmpty ? .history : .suggest
        }
        if !didSubmit {
            return viewModel.searchText.isEmpty ? .history : .suggest
        }
        return submittedResults.isEmpty ? .empty : .result
    }
    
    var body: some View {
        ZStack {
            Colors.backgroundMain.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Custom Navigation Bar
                HStack {
                    Button(action: {
                        if let onClose { onClose() } else { dismiss() }
                    }) {
                        Image("backButton")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                            .foregroundStyle(Colors.NebulaWhite)
                    }
                    
                    Spacer()
                    
                    Text("Search")
                        .fontStyle(Fonts.title1)
                        .foregroundStyle(Colors.NebulaWhite)
                    
                    Spacer()
                    
                    // 빈 공간으로 균형 맞추기
                    Image("backButton")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .opacity(0)
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 20)
                
                // Search Bar
                HStack(spacing: 16) {
                    HStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(Colors.Placeholder)
                        
                        TextField("Search users...", text: $viewModel.searchText)
                            .font(.system(size: 18))
                            .foregroundStyle(Colors.NebulaWhite)
                            .focused($isSearchFocused)
                            .onChange(of: viewModel.searchText) { old, new in
                                guard old != new else { return }
                                didSubmit = false
                                submittedResults = []
                                Task { await viewModel.onChangeSearchText() }
                            }
                            .onSubmit {
                                addHistory(viewModel.searchText)
                                didSubmit = true
                                submittedResults = []
                                Task {
                                    await viewModel.onChangeSearchText()
                                    submittedResults = viewModel.exploreUsers
                                    // show results by removing focus
                                    isSearchFocused = false
                                }
                            }
                        
                        if !viewModel.searchText.isEmpty {
                            Button(action: {
                                viewModel.searchText = ""
                                didSubmit = false
                                submittedResults = []
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 18))
                                    .foregroundStyle(Colors.Placeholder)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Colors.NebulaBlack.opacity(0.3))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Colors.Placeholder.opacity(0.3), lineWidth: 1)
                            )
                    )
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
 
                // After submit, show loading until snapshot ready
                if didSubmit && viewModel.isLoading && submittedResults.isEmpty {
                    VStack(spacing: 16) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Colors.NebulaWhite))
                            .scaleEffect(1.2)
                        Text("Searching...")
                            .fontStyle(Fonts.caption1)
                            .foregroundStyle(Colors.Placeholder)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                } else {
                switch phase {
                case .history:
                    ScrollView {
                        LazyVStack(spacing: 20) {
                            ForEach(searchHistory, id: \.self) { term in
                                HStack {
                                    Text(term)
                                        .fontStyle(Fonts.body1)
                                        .foregroundStyle(Colors.NebulaWhite)
                                        .onTapGesture {
                                            viewModel.searchText = term
                                            didSubmit = false
                                            Task { await viewModel.onChangeSearchText() }
                                        }
                                    Spacer()
                                    Button(action: { removeHistory(term) }) {
                                        Image(systemName: "xmark")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundStyle(Colors.Placeholder)
                                    }
                                }
                                .padding(.horizontal, 24)
                            }
                        }
                    }
                case .suggest:
                    ScrollView {
                        LazyVStack(spacing: 20) {
                            ForEach(viewModel.exploreUsers, id: \.profile.userId) { user in
                                if let card = viewModel.getCardItem(by: user.profile.userId) {
                                    Button(action: {
                                        addHistory(viewModel.searchText)
                                        viewModel.selectedUser = user
                                        viewModel.showingUserSpace = true
                                        if let onClose { onClose() } else { dismiss() }
                                    }) { SuggestionRow(card: card, user: user) }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                case .result:
                    ScrollView {
                        LazyVStack(spacing: 24) {
                            ForEach(submittedResults, id: \.profile.userId) { user in
                                if let card = viewModel.getCardItem(by: user.profile.userId) {
                                    Button(action: {
                                        addHistory(viewModel.searchText)
                                        viewModel.selectedUser = user
                                        viewModel.showingUserSpace = true
                                        if let onClose { onClose() } else { dismiss() }
                                    }) { LargeResultRow(card: card, user: user) }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                case .empty:
                    VStack(spacing: 16) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 48))
                            .foregroundStyle(Colors.Placeholder)
                        Text("We couldn't find a match")
                            .fontStyle(Fonts.title3)
                            .foregroundStyle(Colors.NebulaWhite)
                        Text("Try adjusting your search to find what you are looking for!")
                            .fontStyle(Fonts.caption1)
                            .foregroundStyle(Colors.Placeholder)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                }
                }
 
                Spacer()
            }
        }
        .onAppear {
            isSearchFocused = true
            loadHistory()
            didSubmit = false
            submittedResults = []
        }
        .onChange(of: isSearchFocused) { _, focused in
            if focused {
                // While focused, never show results
                didSubmit = false
                submittedResults = []
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }
    
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
        if searchHistory.count > 10 { searchHistory = Array(searchHistory.prefix(10)) }
        UserDefaults.standard.set(searchHistory, forKey: historyKey)
    }
    private func removeHistory(_ term: String) {
        searchHistory.removeAll { $0 == term }
        UserDefaults.standard.set(searchHistory, forKey: historyKey)
    }
}

// MARK: - Search Result Item View
private struct SearchResultItemView: View {
    let card: ExploreUserCardItem
    let user: ExploreUser
    
    var body: some View {
        HStack(spacing: 16) {
            // Profile Image
            ProfileImageView(
                profile: user.profile,
                size: 56
            )
            
            // User Info
            VStack(alignment: .leading, spacing: 8) {
                Text(card.userName)
                    .fontStyle(Fonts.title3)
                    .foregroundStyle(Colors.NebulaWhite)
                    .lineLimit(1)
                
                HStack(spacing: 16) {
                    VStack(spacing: 4) {
                        Text("\(card.memoryStars)")
                            .fontStyle(Fonts.subheadline)
                            .foregroundStyle(Colors.NebulaWhite)
                        Text("Memories")
                            .fontStyle(Fonts.caption2)
                            .foregroundStyle(Colors.Placeholder)
                    }
                    
                    VStack(spacing: 4) {
                        Text("\(card.likeCount)")
                            .fontStyle(Fonts.subheadline)
                            .foregroundStyle(Colors.NebulaWhite)
                        Text("Likes")
                            .fontStyle(Fonts.caption2)
                            .foregroundStyle(Colors.Placeholder)
                    }
                }
            }
            
            Spacer()
            
            // Arrow Icon
            Image(systemName: "chevron.right")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Colors.Placeholder)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Colors.NebulaBlack.opacity(0.3))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Colors.Placeholder.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Suggestion Row (compact)
private struct SuggestionRow: View {
    let card: ExploreUserCardItem
    let user: ExploreUser
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .stroke(Colors.Placeholder, lineWidth: 2)
                .frame(width: 22, height: 22)
            VStack(alignment: .leading, spacing: 4) {
                Text(card.userName)
                    .fontStyle(Fonts.body1)
                    .foregroundStyle(Colors.NebulaWhite)
                Text("\(card.memoryStars) Memory Stars, \(card.likeCount) Likes")
                    .fontStyle(Fonts.caption2)
                    .foregroundStyle(Colors.Placeholder)
            }
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
    }
}

// MARK: - Large Result Row (thumbnail + info)
private struct LargeResultRow: View {
    let card: ExploreUserCardItem
    let user: ExploreUser
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(card.imageName)
                .resizable()
                .scaledToFill()
                .frame(width: UIScreen.main.bounds.width * 0.61,
                       height: UIScreen.main.bounds.width * 0.61 * (152.0 / 240.0))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(LinearGradient.SearchUsercardBG, lineWidth: 3)
                )
            VStack(alignment: .leading, spacing: 8) {
                Text(card.userName)
                    .fontStyle(Fonts.subheadline)
                    .foregroundStyle(Colors.NebulaWhite)
                Text("\(card.memoryStars) Memory Stars")
                    .fontStyle(Fonts.caption2)
                    .foregroundStyle(Colors.Placeholder)
            }
            Spacer()
        }
    }
}

#Preview {
    iOSExploreSearchView(
        viewModel: ExploreViewModel(
            exploreUseCase: ExploreUseCase(
                authRepository: AuthRepository(supabase: SupabaseClient(
                    supabaseURL: URL(string: "https://example.com")!,
                    supabaseKey: "key"
                )),
                memoryRepository: MemoryRepository(supabase: SupabaseClient(
                    supabaseURL: URL(string: "https://example.com")!,
                    supabaseKey: "key"
                ))
            ),
            appState: AppState(),
            diContainer: DIContainer()
        ),
        onClose: nil
    )
}
