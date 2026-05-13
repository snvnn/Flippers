import Foundation
import SwiftData

@Model
final class Deck: Identifiable {
    var id: UUID = UUID()
    var name: String = ""
    var createdAt: Date = Date()

    var user: User?

    @Relationship(deleteRule: .cascade, inverse: \DeckSection.deck)
    var sections: [DeckSection] = []

    @Relationship(deleteRule: .cascade, inverse: \Card.deck)
    var cards: [Card] = []

    init(name: String) {
        self.name = name
    }

    var dueCount: Int {
        let now = Date()
        return cards.filter { card in
            guard let state = card.srsState else { return false }
            return state.dueDate <= now
        }.count
    }
}
