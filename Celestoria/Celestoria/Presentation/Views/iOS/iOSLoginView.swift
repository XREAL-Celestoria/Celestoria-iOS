//
//  iOSLoginView.swift
//  Celestoria
//
//  Created by Assistant on 2025/07/19.
//

import SwiftUI
import AuthenticationServices

struct iOSLoginView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject var viewModel: LoginViewModel
    
    var body: some View {
        ZStack {
            // Background
            Color.NebulaBlack
                .ignoresSafeArea()
            
            VStack {
                Spacer()
                
                // Header
                iOSHeaderView(
                    title: "Celestoria",
                    subtitle: "Spatial Video Social Network"
                )
                
                Spacer()
                
                // Sign in with Apple Button
                SignInWithAppleButton(.signIn, onRequest: { request in
                    viewModel.prepareRequest(request: request)
                }, onCompletion: { result in
                    viewModel.handleAuthorization(result: result) { userId in
                        // Navigation handled by viewModel and appState
                    }
                })
                .frame(height: 52)
                .cornerRadius(12)
                .signInWithAppleButtonStyle(.white)
                .padding(.horizontal, 24)
                
                Spacer()
                    .frame(height: 100)
            }
            .padding()
            
            // Error popup overlay
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
                        .foregroundColor(.NebulaWhite)
                    
                    Text(errorMessage)
                        .font(.system(size: 16))
                        .foregroundColor(.NebulaWhite)
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
                        .fill(Color.Profile)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.NebulaWhite.opacity(0.2), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 40)
            }
        }
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
}