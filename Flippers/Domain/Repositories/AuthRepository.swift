import Foundation

/// Authentication user value type — no framework dependency
struct AuthUser {
    let uid: String
    let email: String?
}

/// Authentication repository protocol
/// Domain layer — import FirebaseAuth 금지
protocol AuthRepository {
    var currentUser: AuthUser? { get }
    func signInWithEmail(email: String, password: String) async throws -> AuthUser
    func signUpWithEmail(email: String, password: String) async throws -> AuthUser
    func signInWithApple(idToken: String, rawNonce: String, fullName: PersonNameComponents?) async throws -> AuthUser
    func signOut() throws
    func addAuthStateListener(_ listener: @escaping (AuthUser?) -> Void) -> Any
}
