//
//  MemoryTabContent.swift
//  Celestoria-iOS
//
//  Created by Seyoung Park on 8/7/25.
//

import SwiftUI

// MARK: - Memories Tab Content
struct MemoriesTabContentView: View {
    @ObservedObject var viewModel: UserInfoModalViewModel
    let selectedCategories: Set<MemoryCategory>
    @State private var sortOption: MemorySortOption = .latest
    @EnvironmentObject var appState: AppState
    
    enum MemorySortOption: String, CaseIterable {
        case latest = "Latest"
        case oldest = "Oldest"
        
        var displayName: String {
            return self.rawValue
        }
    }
    
    enum MemoryCategory: String, CaseIterable {
        case travel = "TRAVEL"
        case family = "FAMILY"
        case entertainment = "ENTERTAINMENT"
        case pet = "PET"
        
        var displayName: String {
            switch self {
            case .travel: return "Travel"
            case .family: return "Family"
            case .entertainment: return "Entertainment"
            case .pet: return "Pet"
            }
        }
        
        var iconName: String {
            switch self {
            case .travel: return "Travel"
            case .family: return "Family"
            case .entertainment: return "Entertainment"
            case .pet: return "Pet"
            }
        }
    }
    
    var body: some View {
        ZStack {
            VStack {
                Spacer()
                    .frame(height: 82)
                
                LazyVStack(spacing: 40) {
                    ForEach(sortedAndFilteredMemories) { memory in
                        MemoryListItemView(memory: memory)
                            .environmentObject(appState)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .top)
                
                Spacer()
            }
            
            VStack(spacing: 0) {
                // Sort Section
                SortSectionView(viewModel: viewModel)
                
                Spacer()

            }
        }
        .onChange(of: appState.shouldNavigateToMemoryDetail) { shouldNavigate in
            if shouldNavigate {
                // 네비게이션 상태를 리셋
                appState.shouldNavigateToMemoryDetail = false
            }
        }
    }
    
    private var sortedAndFilteredMemories: [Memory] {
        var memories = viewModel.memories
        
        // Apply category filtering
        if !selectedCategories.isEmpty {
            let selectedCategoryStrings = selectedCategories.map { $0.rawValue }
            memories = memories.filter { memory in
                selectedCategoryStrings.contains(memory.category.rawValue)
            }
        }
        
        return memories
    }
}
