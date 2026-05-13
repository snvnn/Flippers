import Foundation
import SwiftData

enum CardType: String, Codable, CaseIterable {
    case word
    case kanji

    var displayName: String {
        switch self {
        case .word:  return "단어 カード"
        case .kanji: return "漢字 カード"
        }
    }

    var templateFields: [(name: String, placeholder: String)] {
        switch self {
        case .word:
            return [
                ("word",    "経験"),
                ("reading", "けいけん"),
                ("meaning", "경험, experience"),
                ("example", "彼は経験が豊富だ。（선택）"),
            ]
        case .kanji:
            return [
                ("kanji",   "龍"),
                ("meaning", "용, dragon"),
                ("onyomi",  "リュウ"),
                ("kunyomi", "たつ"),
            ]
        }
    }
}

enum CreatedSource: String, Codable {
    case ocr
    case manual
    case imported
}

@Model
final class Card: Identifiable {
    var id: UUID = UUID()
    var typeRaw: String = CardType.word.rawValue
    var createdSourceRaw: String = CreatedSource.manual.rawValue
    var createdAt: Date = Date()
    var presetID: String?
    var presetVersion: Int?
    var sourceLabel: String?

    var deck: Deck?
    var section: DeckSection?

    @Relationship(deleteRule: .cascade, inverse: \CardField.card)
    var fields: [CardField] = []

    @Relationship(deleteRule: .cascade, inverse: \SRSState.card)
    var srsState: SRSState?

    @Relationship(deleteRule: .cascade, inverse: \ReviewLog.card)
    var reviewLogs: [ReviewLog] = []

    // MARK: - Enum bridges

    var type: CardType {
        get { CardType(rawValue: typeRaw) ?? .word }
        set { typeRaw = newValue.rawValue }
    }

    var createdSource: CreatedSource {
        get { CreatedSource(rawValue: createdSourceRaw) ?? .manual }
        set { createdSourceRaw = newValue.rawValue }
    }

    init(type: CardType, createdSource: CreatedSource) {
        self.typeRaw = type.rawValue
        self.createdSourceRaw = createdSource.rawValue
    }

    // MARK: - Convenience field accessors

    func field(named name: String) -> String? {
        fields.first { $0.fieldName == name }?.fieldValue
    }

    func normalizedField(named name: String) -> String? {
        guard let value = field(named: name)?.trimmingCharacters(in: .whitespacesAndNewlines),
              !value.isEmpty else {
            return nil
        }
        return value
    }

    var primaryDisplayValue: String {
        switch type {
        case .word:  return normalizedField(named: "word")  ?? ""
        case .kanji: return normalizedField(named: "kanji") ?? ""
        }
    }

    var readingValue: String? {
        normalizedField(named: "reading")
    }

    var meaningValue: String? {
        normalizedField(named: "meaning")
    }

    var exampleValue: String? {
        normalizedField(named: "example")
    }

    var studyReadingHint: String? {
        switch type {
        case .word:
            return readingValue
        case .kanji:
            let parts = [
                normalizedField(named: "kunyomi").map { "訓読み \($0)" },
                normalizedField(named: "onyomi").map { "音読み \($0)" },
            ].compactMap { $0 }
            return parts.isEmpty ? nil : parts.joined(separator: " · ")
        }
    }
}
