//
//  LoginViewModel.swift
//  Celestoria
//
//  Created by Park Seyoung on 1/20/25.
//

import Foundation
import Combine
import AuthenticationServices

@MainActor
class LoginViewModel: NSObject, ObservableObject, ASAuthorizationControllerDelegate {
    private let signInUseCase: SignInWithAppleUseCase
    private var cancellables = Set<AnyCancellable>()
    private let profileUseCase: ProfileUseCase
    private let appModel: AppModel
    
    @Published var errorMessage: String?
    @Published var userId: UUID?
    @Published var showErrorPopup: Bool = false

    init(
        signInUseCase: SignInWithAppleUseCase,
        profileUseCase: ProfileUseCase,
        appModel: AppModel
    ) {
        self.signInUseCase = signInUseCase
        self.profileUseCase = profileUseCase
        self.appModel = appModel
    }

    func prepareRequest(request: ASAuthorizationAppleIDRequest) {
        request.requestedScopes = [.fullName, .email]
    }

    func handleAuthorization(result: Result<ASAuthorization, Error>, completion: @escaping (UUID?) -> Void) {
        switch result {
        case .success(let authorization):
            handleAppleAuthorization(authorization)
                .receive(on: DispatchQueue.main)
                .sink(receiveCompletion: { [weak self] completionResult in
                    if case .failure(let error) = completionResult {
                        self?.errorMessage = "Please try again."
                        self?.showErrorPopup = true
                        completion(nil)
                    }
                }, receiveValue: { [weak self] userId in
                    // 로그인 성공 처리
                    self?.errorMessage = nil
                    self?.userId = userId
                    self?.showErrorPopup = false

                    Task {
                        do {
                            guard let self = self else { return }
                            let fetchedProfile = try await self.profileUseCase.fetchProfile()
                            
                            // AppModel 업데이트 (starfield 등 didSet을 통해 화면 전환 관련 로직이 있을 수 있음)
                            self.appModel.userId = userId
                            self.appModel.userProfile = fetchedProfile
                            
                            // 아직 Terms 동의가 되어 있지 않으면 .terms로 전환
                            if self.appModel.hasAcceptedTerms {
                                self.appModel.activeScreen = .main
                            } else {
                                self.appModel.activeScreen = .terms
                            }
                            
                            completion(userId)
                        } catch {
                            self?.errorMessage = "Please try again."
                            self?.showErrorPopup = true
                            completion(nil)
                        }
                    }
                })
                .store(in: &cancellables)
        case .failure:
            DispatchQueue.main.async {
                self.errorMessage = "Please try again."
                self.showErrorPopup = true
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

