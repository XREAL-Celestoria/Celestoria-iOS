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
                    // 1) 애플 로그인(토큰) 인증 성공 → userId 얻음
                    self?.errorMessage = nil
                    self?.userId = userId
                    self?.showErrorPopup = false

                    // 2) 이제 Supabase에서 프로필도 가져와 AppModel에 반영
                    Task {
                        do {
                            guard let self = self else { return }
                            let fetchedProfile = try await self.profileUseCase.fetchProfile()

                            // AppModel에 넣어주면 starfield가 didSet에서 업데이트됨
                            self.appModel.userId = userId
                            self.appModel.userProfile = fetchedProfile

                            // 로그인 완료 후 메인 화면으로 전환
                            self.appModel.activeScreen = .main

                            // 끝
                            completion(userId)
                        } catch {
                            self?.errorMessage = "Please try again."
                            self?.showErrorPopup = true
                            completion(nil)
                        }
                    }
                })
                .store(in: &cancellables)
        case .failure(let error):
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

