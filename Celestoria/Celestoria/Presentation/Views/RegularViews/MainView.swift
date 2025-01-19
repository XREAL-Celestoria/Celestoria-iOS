//
//  MainView.swift
//  Celestoria
//
//  Created by Park Seyoung on 1/20/25.
//

import SwiftUI

struct MainView: View {
    @EnvironmentObject var viewModel: MainViewModel
    @EnvironmentObject var appModel: AppModel
    @State private var activeScreen: ActiveScreen = .main

    var body: some View {
        ZStack {
            VStack {
                header
                Spacer().frame(height: 20)
                AddMemoryButton { activeScreen = .addMemory }
                Spacer()
                tabMenu
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .padding(.horizontal)
            
            if viewModel.isLoading {
                loadingView
            }

            if let errorMessage = viewModel.errorMessage {
                ErrorBannerView(message: errorMessage)
            }
        }
        .onAppear {
            viewModel.fetchMemories(for: appModel.userId)
        }
    }
}


// MARK: - Subviews
private extension MainView {
    var header: some View {
        VStack(spacing: 10) {
            Text("Celestoria")
                .font(.system(size: 96, weight: .bold, design: .default))
                .foregroundStyle(LinearGradient.GradientMain)
                .multilineTextAlignment(.center)

            Text("SpatialVideo Social Network")
                .font(.system(size: 29, weight: .bold, design: .default))
                .foregroundStyle(LinearGradient.GradientMain)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 20)
    }

    var tabMenu: some View {
        HStack(spacing: 40) {
            MainButton(icon: "globe", text: "Nebula") {
                // Navigation Logic
            }
            MainButton(icon: "magnifyingglass", text: "Explore") {
                // Navigation Logic
            }
            MainButton(icon: "gearshape", text: "Setting") {
                // Navigation Logic
            }
        }
        .padding(.bottom, 30)
    }

    var loadingView: some View {
        ProgressView()
            .scaleEffect(1.5)
            .progressViewStyle(CircularProgressViewStyle(tint: .white))
    }
}
