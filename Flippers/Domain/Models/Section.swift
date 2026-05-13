import Foundation
import SwiftData

@Model
final class DeckSection: Identifiable {
    var id: UUID = UUID()
    var name: String = ""
    var createdAt: Date = Date()

    var deck: Deck?

    @Relationship(deleteRule: .cascade, inverse: \Card.section)
    var cards: [Card] = []

    init(name: String) {
        self.name = name
    }
}
