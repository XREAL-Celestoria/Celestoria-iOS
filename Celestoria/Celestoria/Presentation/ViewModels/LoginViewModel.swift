//
//  LoginViewModel.swift
//  Celestoria
//
//  Created by Park Seyoung on 1/20/25.
//

import Foundation
import Combine
import AuthenticationServices
import os

@MainActor
class LoginViewModel: NSObject, ObservableObject, ASAuthorizationControllerDelegate {
    private let signInUseCase: SignInWithAppleUseCase
    private var cancellables = Set<AnyCancellable>()
    private let profileUseCase: ProfileUseCase
    private let appState: AppState
    
    @Published var errorMessage: String?
    @Published var userId: UUID?
    @Published var showErrorPopup: Bool = false
    @Published var isLoggingIn: Bool = false

    init(
        signInUseCase: SignInWithAppleUseCase,
        profileUseCase: ProfileUseCase,
        appState: AppState
    ) {
        self.signInUseCase = signInUseCase
        self.profileUseCase = profileUseCase
        self.appState = appState
    }

    func prepareRequest(request: ASAuthorizationAppleIDRequest) {
        request.requestedScopes = [.fullName, .email]
    }

    func handleAuthorization(result: Result<ASAuthorization, Error>, completion: @escaping (UUID?) -> Void) {
        isLoggingIn = true
        
        switch result {
        case .success(let authorization):
            handleAppleAuthorization(authorization)
                .receive(on: DispatchQueue.main)
                .sink(receiveCompletion: { [weak self] completionResult in
                    if case .failure(let error) = completionResult {
                        self?.errorMessage = "Please try again."
                        self?.showErrorPopup = true
                        self?.isLoggingIn = false
                        completion(nil)
                    }
                }, receiveValue: { [weak self] userId in
                    // 로그인 성공 처리
                    self?.errorMessage = nil
                    self?.isLoggingIn = false
                    self?.userId = userId
                    self?.showErrorPopup = false

                    Task {
                        do {
                            guard let self = self else { return }
                            let fetchedProfile = try await self.profileUseCase.fetchProfile()
                            
                            // AppState 업데이트 (이미지 로딩은 하지 않음)
                            self.appState.setUser(fetchedProfile, userId: userId)
                            
                            // iOS에서는 navigationState 사용, visionOS에서는 activeScreen 사용
                            #if os(iOS)
                            if self.appState.hasAcceptedTerms {
                                // 약관 동의 완료된 사용자 - 리소스 로딩 후 메인으로 이동
                                Task {
                                    // 프로필 이미지 미리 로딩
                                    if let profileImageURL = fetchedProfile.profileImageURL {
                                        await ImageCache.shared.preloadProfileImage(urlString: profileImageURL)
                                        Logger.info("LoginViewModel: Preloaded profile image for returning user")
                                    }
                                }
                                // 갤럭시 로딩을 다시 시작하도록 설정
                                self.appState.isGalaxyLoadingComplete = false
                                self.appState.navigationState = .main
                            } else {
                                self.appState.navigationState = .terms
                            }
                            #else
                            // 아직 Terms 동의가 되어 있지 않으면 .terms로 전환
                            if self.appState.hasAcceptedTerms {
                                self.appState.activeScreen = .main
                            } else {
                                self.appState.activeScreen = .terms
                            }
                            #endif
                            
                            completion(userId)
                        } catch {
                            self?.errorMessage = "Please try again."
                            self?.showErrorPopup = true
                            self?.isLoggingIn = false
                            completion(nil)
                        }
                    }
                })
                .store(in: &cancellables)
        case .failure:
            DispatchQueue.main.async {
                self.errorMessage = "Please try again."
                self.showErrorPopup = true
                self.isLoggingIn = false
                completion(nil)
            }
        }
    }

    private func handleAppleAuthorization(_ authorization: ASAuthorization) -> AnyPublisher<UUID, Error> {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let identityToken = appleIDCredential.identityToken,
              let idToken = String(data: identityToken, encoding: .utf8) else {
            return Fail(error: NSError(
                domain: "LoginError",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Failed to retrieve or convert Apple identity token."]
            )).eraseToAnyPublisher()
        }

        return Future { [weak self] promise in
            Task {
                do {
                    let userId = try await self?.signInUseCase.execute(idToken: idToken)
                    promise(.success(userId ?? UUID()))
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
}

