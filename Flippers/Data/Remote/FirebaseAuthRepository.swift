import Foundation
import FirebaseAuth

enum AuthError: LocalizedError, Equatable {
    case appleSignInRequiresUI
    case invalidEmail
    case invalidCredentials
    case missingToken
    case userNotFound
    case emailAlreadyInUse
    case weakPassword
    case network
    case tooManyRequests
    case userDisabled
    case firebaseUnavailable(String)

    var errorDescription: String? {
        switch self {
        case .appleSignInRequiresUI:
            return "Apple 로그인은 UI에서 처리됩니다."
        case .invalidEmail:
            return "이메일 형식이 올바르지 않습니다."
        case .invalidCredentials:
            return "이메일 또는 비밀번호가 올바르지 않습니다."
        case .missingToken:
            return "인증 토큰이 누락되었습니다."
        case .userNotFound:
            return "등록된 계정이 없습니다."
        case .emailAlreadyInUse:
            return "이미 사용 중인 이메일입니다."
        case .weakPassword:
            return "비밀번호는 6자 이상이어야 합니다."
        case .network:
            return "네트워크 연결을 확인해주세요."
        case .tooManyRequests:
            return "잠시 후 다시 시도해주세요. (요청 횟수 초과)"
        case .userDisabled:
            return "비활성화된 계정입니다. 고객센터에 문의해주세요."
        case .firebaseUnavailable(let message):
            return message
        }
    }
}

final class FirebaseAuthRepository: AuthRepository {

    var currentUser: AuthUser? {
        guard let user = Auth.auth().currentUser else { return nil }
        return AuthUser(uid: user.uid, email: user.email)
    }

    func signInWithEmail(email: String, password: String) async throws -> AuthUser {
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            return AuthUser(uid: result.user.uid, email: result.user.email)
        } catch {
            throw Self.mapFirebaseError(error)
        }
    }

    func signUpWithEmail(email: String, password: String) async throws -> AuthUser {
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            return AuthUser(uid: result.user.uid, email: result.user.email)
        } catch {
            throw Self.mapFirebaseError(error)
        }
    }

    func signInWithApple(idToken: String, rawNonce: String, fullName: PersonNameComponents?) async throws -> AuthUser {
        let credential = OAuthProvider.appleCredential(
            withIDToken: idToken,
            rawNonce: rawNonce,
            fullName: fullName
        )
        do {
            let result = try await Auth.auth().signIn(with: credential)
            return AuthUser(uid: result.user.uid, email: result.user.email)
        } catch {
            throw Self.mapFirebaseError(error)
        }
    }

    func signOut() throws {
        try Auth.auth().signOut()
    }

    func addAuthStateListener(_ listener: @escaping (AuthUser?) -> Void) -> Any {
        Auth.auth().addStateDidChangeListener { _, user in
            if let user {
                listener(AuthUser(uid: user.uid, email: user.email))
            } else {
                listener(nil)
            }
        }
    }

    static func mapFirebaseError(_ error: Error) -> Error {
        let nsError = error as NSError
        guard nsError.domain == AuthErrorDomain,
              let code = AuthErrorCode(rawValue: nsError.code) else {
            return error
        }

        switch code {
        case .invalidEmail:
            return AuthError.invalidEmail
        case .wrongPassword, .invalidCredential:
            return AuthError.invalidCredentials
        case .userNotFound:
            return AuthError.userNotFound
        case .emailAlreadyInUse:
            return AuthError.emailAlreadyInUse
        case .weakPassword:
            return AuthError.weakPassword
        case .networkError:
            return AuthError.network
        case .tooManyRequests:
            return AuthError.tooManyRequests
        case .userDisabled:
            return AuthError.userDisabled
        default:
            return error
        }
    }
}

final class UnavailableAuthRepository: AuthRepository {
    private let message: String

    init(message: String) {
        self.message = message
    }

    var currentUser: AuthUser? { nil }

    func signInWithEmail(email: String, password: String) async throws -> AuthUser {
        throw AuthError.firebaseUnavailable(message)
    }

    func signUpWithEmail(email: String, password: String) async throws -> AuthUser {
        throw AuthError.firebaseUnavailable(message)
    }

    func signInWithApple(idToken: String, rawNonce: String, fullName: PersonNameComponents?) async throws -> AuthUser {
        throw AuthError.firebaseUnavailable(message)
    }

    func signOut() throws {}

    func addAuthStateListener(_ listener: @escaping (AuthUser?) -> Void) -> Any {
        listener(nil)
        return UUID()
    }
}
