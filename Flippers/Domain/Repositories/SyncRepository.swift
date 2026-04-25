import Foundation

/// Cloud sync repository protocol
/// Domain layer — import FirebaseFirestore 금지
protocol SyncRepository {
    func uploadDeck(_ data: [String: Any], userUID: String) async throws
    func uploadCard(_ data: [String: Any], userUID: String) async throws
    func uploadSRSState(_ data: [String: Any], userUID: String) async throws
    func uploadReviewLog(_ data: [String: Any], userUID: String) async throws
    func fetchAllDecks(userUID: String) async throws -> [[String: Any]]
    func fetchAllCards(userUID: String) async throws -> [[String: Any]]
}
