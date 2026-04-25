import SwiftUI
import AuthenticationServices
import CryptoKit

@Observable
@MainActor
final class AuthViewModel {
    var currentUserUID: String?
    var isLoading = false
    var errorMessage: String?
    var configurationMessage: String?

    // Email form
    var email = ""
    var password = ""
    var isSignUpMode = false

    private let authRepository: AuthRepository
    private var currentNonce: String?
    private var authStateHandle: Any?

    init(authRepository: AuthRepository, configurationMessage: String? = nil) {
        self.authRepository = authRepository
        self.configurationMessage = configurationMessage
        setupAuthListener()
    }

    convenience init() {
        let status = FirebaseBootstrap.configureIfAvailable()
        if status.isConfigured {
            self.init(authRepository: FirebaseAuthRepository())
        } else {
            let message = status.userMessage ?? "Firebase 구성이 없어 로그인을 사용할 수 없습니다."
            self.init(
                authRepository: UnavailableAuthRepository(message: message),
                configurationMessage: message
            )
        }
    }

    // MARK: - Auth State

    private func setupAuthListener() {
        authStateHandle = authRepository.addAuthStateListener { [weak self] user in
            Task { @MainActor in
                self?.currentUserUID = user?.uid
            }
        }
    }

    var isLoggedIn: Bool { currentUserUID != nil }
    var isAuthenticationAvailable: Bool { configurationMessage == nil }
    var shouldShowAuthentication: Bool { isAuthenticationAvailable && !isLoggedIn }

    // MARK: - Email Auth

    func submitEmail() async {
        guard isAuthenticationAvailable else {
            errorMessage = configurationMessage
            return
        }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let user: AuthUser
            if isSignUpMode {
                user = try await authRepository.signUpWithEmail(email: email, password: password)
            } else {
                user = try await authRepository.signInWithEmail(email: email, password: password)
            }
            currentUserUID = user.uid
        } catch {
            errorMessage = koreanMessage(for: error)
        }
    }

    func signOut() {
        do {
            try authRepository.signOut()
            currentUserUID = nil
        } catch {
            errorMessage = koreanMessage(for: error)
        }
    }

    // MARK: - Apple Sign In

    func prepareAppleSignInRequest(_ request: ASAuthorizationAppleIDRequest) {
        guard isAuthenticationAvailable else {
            errorMessage = configurationMessage
            return
        }
        let nonce = randomNonce()
        currentNonce = nonce
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
    }

    func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) async {
        guard isAuthenticationAvailable else {
            errorMessage = configurationMessage
            return
        }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        switch result {
        case .success(let auth):
            guard
                let credential = auth.credential as? ASAuthorizationAppleIDCredential,
                let tokenData = credential.identityToken,
                let tokenString = String(data: tokenData, encoding: .utf8),
                let nonce = currentNonce
            else {
                errorMessage = "Apple 로그인 정보를 처리할 수 없습니다."
                return
            }
            do {
                let user = try await authRepository.signInWithApple(
                    idToken: tokenString,
                    rawNonce: nonce,
                    fullName: credential.fullName
                )
                currentUserUID = user.uid
            } catch {
                errorMessage = koreanMessage(for: error)
            }
        case .failure(let error):
            if (error as NSError).code == ASAuthorizationError.canceled.rawValue {
                return
            }
            errorMessage = koreanMessage(for: error)
        }
    }

    // MARK: - Helpers

    private func koreanMessage(for error: Error) -> String {
        if let authError = error as? AuthError,
           let message = authError.errorDescription {
            return message
        }
        return error.localizedDescription
    }

    private func randomNonce(length: Int = 32) -> String {
        var randomBytes = [UInt8](repeating: 0, count: length)
        _ = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        return randomBytes.map { String(format: "%02x", $0) }.joined()
    }

    private func sha256(_ input: String) -> String {
        let data = Data(input.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
}
