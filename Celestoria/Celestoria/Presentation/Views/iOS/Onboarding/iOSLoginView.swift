//
//  iOSLoginView.swift
//  Celestoria
//
//  Created by Minjun Kim on 7/20/25.
//

import SwiftUI
import AuthenticationServices

struct iOSLoginView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject var viewModel: LoginViewModel
    
    var body: some View {
        ZStack {
            VStack(alignment: .center) {
                Spacer()
                
                iOSHeaderView(
                    title: "Celestoria",
                    subtitle: "Spatial Video Social Network"
                )
                
                Spacer()
                    .frame(height: UIScreen.main.bounds.height * 0.4)
                
                SignInWithAppleButton(.signIn,
                                      onRequest: { request in
                    viewModel.prepareRequest(request: request)
                },
                                      onCompletion: handleAppleLogin
                )
                .frame(height: 56)
                .cornerRadius(12)
                .signInWithAppleButtonStyle(.white)
                .padding(.horizontal, 24)
                .padding(.bottom, 60)
                .disabled(viewModel.isLoggingIn)
                .opacity(viewModel.isLoggingIn ? 0.6 : 1.0)
            }
            
            errorPopupView
        }
        .background(Colors.backgroundMain)
        .onChange(of: viewModel.errorMessage) { _, newValue in
            if newValue != nil {
                viewModel.showErrorPopup = true
            }
        }
        .onAppear {
            viewModel.showErrorPopup = false
            viewModel.errorMessage = nil
        }
    }

    @ViewBuilder
    private var errorPopupView: some View {
        if viewModel.showErrorPopup, let errorMessage = viewModel.errorMessage {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    viewModel.showErrorPopup = false
                    viewModel.errorMessage = nil
                }

            VStack(spacing: 20) {
                Text("Login Error")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Colors.NebulaWhite)

                Text(errorMessage)
                    .font(.system(size: 16))
                    .foregroundColor(Colors.NebulaWhite)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                iOSMainButton(
                    title: "Close",
                    action: {
                        viewModel.showErrorPopup = false
                        viewModel.errorMessage = nil
                    },
                    isEnabled: true
                )
                .padding(.horizontal, 40)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Colors.Profile)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Colors.NebulaWhite.opacity(0.2), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 40)
        }
    }
    
    private func handleAppleLogin(result: Result<ASAuthorization, Error>) {
        viewModel.handleAuthorization(result: result) { userId in
            // Navigation handled by viewModel and appState
        }
    }
}
