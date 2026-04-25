import Foundation
import FirebaseFirestore

enum SyncError: LocalizedError {
    case firebaseUnavailable(String)

    var errorDescription: String? {
        switch self {
        case .firebaseUnavailable(let message):
            return message
        }
    }
}

actor FirebaseSyncService: SyncRepository {

    static let shared = FirebaseSyncService()

    private func database() throws -> Firestore {
        let status = FirebaseBootstrap.configureIfAvailable()
        guard status.isConfigured else {
            throw SyncError.firebaseUnavailable(
                status.userMessage ?? "Firebase 구성이 없어 클라우드 동기화를 사용할 수 없습니다."
            )
        }
        return Firestore.firestore()
    }

    // MARK: - Deck

    func uploadDeck(_ data: [String: Any], userUID: String) async throws {
        let db = try database()
        guard let deckID = data["id"] as? String else { return }
        try await db.collection("users").document(userUID)
            .collection("decks").document(deckID)
            .setData(data, merge: true)
    }

    // MARK: - Card

    func uploadCard(_ data: [String: Any], userUID: String) async throws {
        let db = try database()
        guard let cardID = data["id"] as? String else { return }
        try await db.collection("users").document(userUID)
            .collection("cards").document(cardID)
            .setData(data, merge: true)
    }

    // MARK: - SRSState

    func uploadSRSState(_ data: [String: Any], userUID: String) async throws {
        let db = try database()
        guard let cardID = data["cardID"] as? String else { return }
        try await db.collection("users").document(userUID)
            .collection("srsStates").document(cardID)
            .setData(data, merge: true)
    }

    // MARK: - ReviewLog

    func uploadReviewLog(_ data: [String: Any], userUID: String) async throws {
        let db = try database()
        guard let logID = data["id"] as? String else { return }
        try await db.collection("users").document(userUID)
            .collection("reviewLogs").document(logID)
            .setData(data, merge: true)
    }

    // MARK: - Fetch

    func fetchAllDecks(userUID: String) async throws -> [[String: Any]] {
        let db = try database()
        let snapshot = try await db.collection("users").document(userUID)
            .collection("decks").getDocuments()
        return snapshot.documents.map { $0.data() }
    }

    func fetchAllCards(userUID: String) async throws -> [[String: Any]] {
        let db = try database()
        let snapshot = try await db.collection("users").document(userUID)
            .collection("cards").getDocuments()
        return snapshot.documents.map { $0.data() }
    }
}
