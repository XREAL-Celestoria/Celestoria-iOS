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

    @State private var cardItem: ExploreUserCardItem?
    @State private var isLoading: Bool = true

    var body: some View {
        ZStack {
            if let cardItem = cardItem {
                VStack {
                    Text("Exploring \(cardItem.userName)'s Galaxy")
                        .font(.title2)
                        .foregroundColor(.white)

                    if isLoading {
                        ProgressView("Loading...")
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Galaxy Loaded!")
                            .font(.headline)
                            .foregroundColor(.green)
                    }

                    Button("Close") {
                        dismissWindow()
                    }
                    .padding(.top, 20)
                }
                .padding()
            } else {
                Text("User not found")
                    .font(.title)
                    .foregroundColor(.white)
            }
        }
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.edgesIgnoringSafeArea(.all))
    }
}

