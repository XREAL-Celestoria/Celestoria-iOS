//
//  LoginView.swift
//  Celestoria
//
//  Created by Park Seyoung on 1/20/25.
//

import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @EnvironmentObject private var appModel: AppModel
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @EnvironmentObject var viewModel: LoginViewModel

    var body: some View {
        GeometryReader { geometry in
            VStack {
                HeaderView(title: "Celestoria", subtitle: "Spatial Video Social Network")
                    .padding(.top, geometry.size.height * 0.2)
                Spacer()
                    .frame(height: geometry.size.height * 0.2)
                SignInWithAppleButton(.signIn, onRequest: { request in
                    viewModel.prepareRequest(request: request)
                }, onCompletion: { result in
                    viewModel.handleAuthorization(result: result) { userId in
                        if let userId = userId {
                            appModel.userId = userId
                            startImmersiveExperience()
                            appModel.isImmersiveViewActive = true
                            appModel.activeScreen = .main
                        }
                    }
                })
                .frame(width: 376, height: 64)
                .cornerRadius(16)
                .signInWithAppleButtonStyle(.white)
            }
            .padding()
            
            if let errorMessage = viewModel.errorMessage {
                ErrorBannerView(message: errorMessage) {
                    viewModel.errorMessage = nil
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 16)
                .padding(.top, geometry.safeAreaInsets.top + 10)
                .zIndex(1)
            }
        }
    }

    private func startImmersiveExperience() {
        Task {
            await openImmersiveSpace(id: appModel.immersiveSpaceID)
        }
    }
    //close
    private var errorOverlay: some View {
        Group {
            if let error = viewModel.errorMessage {
                ErrorBannerView(message: error) {
                    viewModel.errorMessage = nil
                }
                .padding(.top, 10)
            } else {
                EmptyView()
            }
        }
    }
}

