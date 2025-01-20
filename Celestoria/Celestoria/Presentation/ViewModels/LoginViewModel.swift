//
//  LoginViewModel.swift
//  Celestoria
//
//  Created by Park Seyoung on 1/20/25.
//

import Foundation
import Combine
import AuthenticationServices

class LoginViewModel: NSObject, ObservableObject {
    private let signInUseCase: SignInWithAppleUseCase
    private var cancellables = Set<AnyCancellable>()
    
    @Published var errorMessage: String?
    @Published var userId: UUID?

    init(signInUseCase: SignInWithAppleUseCase) {
        self.signInUseCase = signInUseCase
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
                        self?.errorMessage = error.localizedDescription
                        completion(nil)
                    }
                }, receiveValue: { [weak self] userId in
                    self?.userId = userId
                    self?.errorMessage = nil
                    completion(userId)
                })
                .store(in: &cancellables)
        case .failure(let error):
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
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

