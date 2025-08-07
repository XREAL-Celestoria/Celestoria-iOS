//
//  CategoryButton.swift
//  Celestoria-iOS
//
//  Created by Seyoung Park on 8/7/25.
//

import SwiftUI

// MARK: - Category Filter Button
struct CategoryFilterButton: View {
    @Binding var selectedCategories: Set<MemoriesTabContentView.MemoryCategory>
    @Binding var showCategoryFilter: Bool
    
    private var displayText: String {
        if selectedCategories.isEmpty {
            return "All"
        } else {
            let categoryNames = selectedCategories.map { $0.displayName }
            return categoryNames.joined(separator: ", ")
        }
    }
    
    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.3)) {
                showCategoryFilter.toggle()
            }
        }) {
            ZStack {
                if showCategoryFilter {
                    // Expanded content
                    VStack {
                        // Individual categories
                        VStack(spacing: 16) {
                            ForEach(MemoriesTabContentView.MemoryCategory.allCases, id: \.self) { category in
                                Button(action: {
                                    toggleCategory(category)
                                }) {
                                    ZStack {
                                        if selectedCategories.contains(category) {
                                            // Selected state - show checkmark icon
                                            Image("\(category.iconName)Modal")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 24, height: 24)
                                        } else {
                                            // Unselected state - show category icon
                                            Image("\(category.iconName)Off")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 24, height: 24)
                                        }
                                    }
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 6)
                                    .background(
                                        Circle()
                                            .fill(selectedCategories.contains(category) ? Color.white.opacity(0.1) : Color.clear)
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.top, 13)
                        
                        Spacer()
                            .frame(height: 16) // 276px 중앙에 정확히 위치하도록 계산
                        
                        // All option - positioned to align with collapsed state filter icon
                        Button(action: {
                            selectedCategories.removeAll()
                            showCategoryFilter = false
                        }) {
                            ZStack {
                                Image("filterIcon")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 26, height: 26)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Spacer()
                            .frame(height: 13)
                    }
                    .opacity(showCategoryFilter ? 1 : 0)
                    .scaleEffect(showCategoryFilter ? 1 : 0.8)
                } else {
                    // Collapsed state - just the filter icon
                    Image("filterIcon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 26, height: 26)
                        .opacity(showCategoryFilter ? 0 : 1)
                        .scaleEffect(showCategoryFilter ? 0.8 : 1)
                }
            }
            .frame(
                width: showCategoryFilter ? 52 : 52
            )
            .frame(height: showCategoryFilter ? 276 : 52)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 26)
                        .fill(
                            Colors.BackgroundBlack.opacity(0.9)
                        )
                    
                    RoundedRectangle(cornerRadius: 26)
                        .fill(
                            LinearGradient.BackgroundPopup
                        )
                }
            )
            .cornerRadius(26)
            .overlay(
                RoundedRectangle(cornerRadius: 26)
                    .inset(by: 0.75)
                    .stroke(Color(red: 0.65, green: 0.91, blue: 1), lineWidth: 1.5)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func toggleCategory(_ category: MemoriesTabContentView.MemoryCategory) {
        if selectedCategories.contains(category) {
            selectedCategories.remove(category)
        } else {
            selectedCategories.insert(category)
        }
    }
}
