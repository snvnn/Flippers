import Foundation
import SwiftData

struct PresetImportResult: Equatable {
    var createdCount: Int
    var skippedCount: Int
    var deckName: String
}

@MainActor
enum PresetImportService {
    static func importPreset(
        _ preset: PresetDefinition,
        into context: ModelContext,
        existingCards: [Card],
        destinationDeck: Deck? = nil
    ) -> PresetImportResult {
        let existingPresetIDs = Set(existingCards.compactMap(\.presetID))
        let cardsToImport = preset.cards.filter { !existingPresetIDs.contains($0.presetID) }

        guard !cardsToImport.isEmpty else {
            return PresetImportResult(
                createdCount: 0,
                skippedCount: preset.cards.count,
                deckName: destinationDeck?.name ?? preset.title
            )
        }

        let deck = destinationDeck ?? Deck(name: preset.title)
        if destinationDeck == nil {
            context.insert(deck)
        }

        var createdCount = 0

        for presetCard in cardsToImport {
            let card = Card(type: presetCard.type, createdSource: .imported)
            card.deck = deck
            card.presetID = presetCard.presetID
            card.presetVersion = preset.version
            card.sourceLabel = preset.title
            context.insert(card)

            for (index, field) in presetCard.fields.enumerated() {
                let value = field.value.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !value.isEmpty else { continue }
                let cardField = CardField(fieldName: field.name, fieldValue: value, sortOrder: index)
                cardField.card = card
                context.insert(cardField)
            }

            let state = SRSState()
            state.card = card
            context.insert(state)

            createdCount += 1
        }

        return PresetImportResult(
            createdCount: createdCount,
            skippedCount: preset.cards.count - createdCount,
            deckName: deck.name
        )
    }
}
