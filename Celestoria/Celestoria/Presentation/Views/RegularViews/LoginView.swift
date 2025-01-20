//
//  LoginView.swift
//  Celestoria
//
//  Created by Park Seyoung on 1/20/25.
//

import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @State private var isImmersiveViewActive = false
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    
    @EnvironmentObject private var appModel: AppModel
    
    @State private var activeScreen: ActiveScreen = .login
    @StateObject private var appleLoginViewModel = LoginViewModel()

    private let mainColor = Color(red: 88/255, green: 86/255, blue: 214/255)
    private let backgroundColor = Color.white

    var body: some View {
        ZStack {
            backgroundColor
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 40) {
                Text("Spatial Nebula")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundColor(mainColor)
                
                Image(systemName: "sparkles")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                    .foregroundColor(mainColor)
                
                VStack(spacing: 20) {
                    Text("Create your personal universe")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Turn emotions and spatial videos into cosmic memories")
                        .font(.subheadline)
                }
                .foregroundColor(mainColor.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                
                // Apple Sign-In Button
                SignInWithAppleButton(.signIn, onRequest: { request in
                    appleLoginViewModel.prepareRequest(request: request)
                }, onCompletion: { result in
                    appleLoginViewModel.handleAuthorization(result: result) { [weak appleLoginViewModel] in
                        if let userId = appleLoginViewModel?.userId {
                            appModel.userId = userId
                            startImmersiveExperience(for: userId)
                        }
                    }
                })
                .frame(width: 300, height: 50)
                .cornerRadius(25)
                .shadow(color: Color.gray.opacity(0.4), radius: 10, x: 0, y: 5)
                .padding()
            }
            .padding()
        }
    }

    private func startImmersiveExperience(for userId: UUID) {
        Task {
            do {
                // Immersive space 개설
                try await openImmersiveSpace(id: "SpaceEnvironment")
                print("여기까지 잘 왔나요?", userId)
                self.activeScreen = .main

                isImmersiveViewActive = true
            } catch {
                print("Failed to open Immersive Space: \(error)")
            }
        }
    }

    private func closeImmersiveExperience() {
        Task {
            await dismissImmersiveSpace()
            isImmersiveViewActive = false
            activeScreen = .login
        }
    }
}

#Preview {
    LoginView()
}
