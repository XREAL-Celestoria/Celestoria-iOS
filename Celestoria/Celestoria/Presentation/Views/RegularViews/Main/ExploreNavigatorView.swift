//
//  ExploreNavigator.swift
//  Celestoria
//
//  Created by Park Seyoung on 1/28/25.
//

import SwiftUI
import os

struct ExploreNavigatorView: View {
    let profileId: UUID
    @EnvironmentObject var appModel: AppModel
    @EnvironmentObject var exploreViewModel: ExploreViewModel
    @EnvironmentObject var spaceCoordinator: SpaceCoordinator
    @Environment(\.dismissWindow) private var dismissWindow
    @Environment(\.openWindow) private var openWindow

    @State private var cardItem: ExploreUserCardItem?
    @State private var isLoading: Bool = true

    var body: some View {
        GradientBorderContainerSmall {
            ZStack {
                VStack(spacing: 10) {
                    NavigationBar(
                        title: "Explore",
                        action: {
                            Task {
                                dismissWindow()
                                appModel.activeScreen = .explore
                                openWindow(id: "Main")
                                if let userId = appModel.userId {
                                    await spaceCoordinator.loadData(for: userId)
                                }
                            }
                        },
                        buttonImageString: "chevron.left"
                    )
                    .padding(.horizontal, -8)
                    .padding(.top, -8)
                    
                    if let cardItem = cardItem {
                        HStack(spacing: 16) {
                            Text("\(cardItem.userName)'s Galaxy")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.white)
                                .offset(y: -4)
                            Spacer()
                                .frame(width: 10)
                            Image("Memory-icon")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)
                            
                            Text("\(cardItem.memoryStars) Memory Stars")
                                .font(.system(size: 24))
                                .foregroundStyle(LinearGradient.GradientMain)
                        }
                        .frame(height: 32)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 24)
                    } else {
                        Text("User not found")
                            .font(.title)
                            .foregroundColor(.white)
                            .padding(.top, 32)
                    }
                    
                    Spacer()
                }
                
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                }
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 44)
                .stroke(Color(red: 0.73, green: 0.74, blue: 1), lineWidth: 16)
        )
        .onAppear {
            cardItem = exploreViewModel.getCardItem(by: profileId)
            if cardItem == nil {
                    os.Logger.error("No cardItem found for profileId: \(profileId)")
                } else {
                    os.Logger.info("Found cardItem: \(cardItem?.userName ?? "Unknown")")
                }
            Task {
                isLoading = true
                await spaceCoordinator.loadData(for: profileId)
                isLoading = false
            }
        }
        .onDisappear {
            appModel.showExploreNavigatorView = false
        }
    }
}

