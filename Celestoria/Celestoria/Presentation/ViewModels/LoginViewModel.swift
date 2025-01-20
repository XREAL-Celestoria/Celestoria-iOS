//
//  LoginViewModel.swift
//  Celestoria
//
//  Created by Park Seyoung on 1/20/25.
//

import Foundation
import AuthenticationServices
import SwiftUI
import Supabase

class LoginViewModel: NSObject, ObservableObject {
    private let supabase: SupabaseClient
    
    @Published var userId: UUID?
    @Published var email: String?
    @Published var isDeleting: Bool = false
    @Published var deleteError: String?

    init(supabase: SupabaseClient = DIContainer.shared.supabaseClient) {
        self.supabase = supabase
    }

    func prepareRequest(request: ASAuthorizationAppleIDRequest) {
        request.requestedScopes = [.fullName, .email]
    }

    func handleAuthorization(result: Result<ASAuthorization, Error>, onSuccess: @escaping () -> Void) {
        switch result {
        case .success(let authorization):
            handleAppleAuthorization(authorization, onSuccess: onSuccess)
        case .failure(let error):
            print("Apple Sign In failed: \(error.localizedDescription)")
        }
    }

    private func handleAppleAuthorization(_ authorization: ASAuthorization, onSuccess: @escaping () -> Void) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let identityToken = appleIDCredential.identityToken,
              let idToken = String(data: identityToken, encoding: .utf8) else {
            print("Failed to retrieve or convert Apple identity token")
            return
        }

        Task {
            do {
                try await signInWithSupabase(idToken: idToken)
                
                if let userId = supabase.auth.currentUser?.id {
                    print("Supabase User ID: \(userId)")
                    
                    DispatchQueue.main.async {
                        self.userId = userId
                        onSuccess()
                    }
                } else {
                    print("Failed to retrieve Supabase user ID")
                }
                
            } catch {
                print("Error during sign-in: \(error.localizedDescription)")
            }
        }
    }

    private func signInWithSupabase(idToken: String) async throws {
        try await supabase.auth.signInWithIdToken(
            credentials: .init(provider: .apple, idToken: idToken)
        )
        print("Sign-in successful with Supabase")
    }
    
    func signOut(onSuccess: @escaping () -> Void) async {
        do {
            try await supabase.auth.signOut()
            
            DispatchQueue.main.async {
                self.userId = nil
                self.email = nil
                onSuccess()
            }
            print("Successfully signed out")
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }
    
    func deleteAccount(onSuccess: @escaping () -> Void) {
        DispatchQueue.main.async {
            self.isDeleting = true
            self.deleteError = nil
        }
        
        Task {
            do {
                let response = try await supabase.rpc("delete_current_user").execute()

                DispatchQueue.main.async {
                    self.userId = nil
                    self.email = nil
                    self.isDeleting = false
                    onSuccess()
                }
                print("Account successfully deleted")
                
            } catch {
                DispatchQueue.main.async {
                    self.isDeleting = false
                    self.deleteError = error.localizedDescription
                }
                print("Failed to delete account: \(error.localizedDescription)")
            }
        }
    }
}

extension LoginViewModel: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            print("No connected window scene found")
            return UIWindow()
        }
        return windowScene.windows.first ?? UIWindow()
    }
}
