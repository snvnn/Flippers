import Foundation
import SwiftData

@Model
final class User {
    var id: UUID = UUID()
    var email: String = ""
    var createdAt: Date = Date()

    @Relationship(deleteRule: .cascade, inverse: \Deck.user)
    var decks: [Deck] = []

    init(email: String) {
        self.email = email
    }
}
