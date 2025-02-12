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
                        // 여기서 직접 appModel 세팅할 필요 없음
                        // userId 있으면 이미 LoginViewModel에서 appModel 업데이트 끝남
                    }
                })
                .frame(width: 376, height: 64)
                .cornerRadius(16)
                .signInWithAppleButtonStyle(.white)
            }
            .padding()
            .onChange(of: viewModel.errorMessage) { newValue in
                if newValue != nil {
                    viewModel.showErrorPopup = true
                }
            }
            .onAppear {
                viewModel.showErrorPopup = false
                viewModel.errorMessage = nil
            }
            
            .onDisappear {
                viewModel.showErrorPopup = false
                viewModel.errorMessage = nil
            }
            
            if viewModel.showErrorPopup, let errorMessage = viewModel.errorMessage {
                ZStack {
                    Color.black.opacity(0.6)
                        .ignoresSafeArea()
                    
                    PopupErrorView(
                        title: "Login Error",
                        notes: errorMessage,
                        trailingButtonText: "Close",
                        circularAction: {
                            viewModel.showErrorPopup = false
                            viewModel.errorMessage = nil
                        },
                        buttonAction: {
                            viewModel.showErrorPopup = false
                            viewModel.errorMessage = nil
                        },
                        buttonImageString: "xmark"
                    )
                    .frame(width: 644, height: 324)
                }
            }
        }
    }
}
