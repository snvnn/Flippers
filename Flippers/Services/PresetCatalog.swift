import Foundation

struct PresetDefinition: Identifiable {
    var id: String
    var title: String
    var subtitle: String
    var version: Int
    var expectedCardCount: Int
    var sourceLabel: String
    var cards: [PresetCardDefinition]

    var sourceNote: String { sourceLabel }

    var isComplete: Bool {
        cards.count == expectedCardCount
    }
}

struct PresetCardDefinition: Identifiable {
    var presetID: String
    var type: CardType
    var sourceLabel: String
    var fields: [(name: String, value: String)]

    var id: String { presetID }
}

enum DefaultPresetCatalog {
    static let presets: [PresetDefinition] = BundlePresetCatalog.loadPresets()
}

enum BundlePresetCatalog {
    static func loadPresets(bundle: Bundle = .main) -> [PresetDefinition] {
        let decodedFiles: [PresetExportFile] = presetResourceURLs(bundle: bundle)
            .compactMap { url -> PresetExportFile? in
                guard let data = try? Data(contentsOf: url) else { return nil }
                return try? decodePreset(data)
            }

        let productionFiles = decodedFiles.filter { file in
            file.exportMode == "production"
        }
        let definitions = productionFiles.map { file in
            file.definition
        }
        return definitions.sorted { lhs, rhs in
            lhs.id < rhs.id
        }
    }

    static func decodePreset(_ data: Data) throws -> PresetExportFile {
        let decoder = JSONDecoder()
        return try decoder.decode(PresetExportFile.self, from: data)
    }

    private static func presetResourceURLs(bundle: Bundle) -> [URL] {
        if let urls = bundle.urls(forResourcesWithExtension: "json", subdirectory: "Presets"), !urls.isEmpty {
            return urls.sorted { $0.lastPathComponent < $1.lastPathComponent }
        }

        return (bundle.urls(forResourcesWithExtension: "json", subdirectory: nil) ?? [])
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
    }
}

struct PresetExportFile: Decodable {
    var id: String
    var title: String
    var subtitle: String
    var version: Int
    var sourceLabel: String
    var expectedCardCount: Int
    var exportMode: String
    var cards: [PresetExportCard]

    var definition: PresetDefinition {
        PresetDefinition(
            id: id,
            title: title,
            subtitle: subtitle,
            version: version,
            expectedCardCount: expectedCardCount,
            sourceLabel: sourceLabel,
            cards: cards.map(\.definition)
        )
    }
}

struct PresetExportCard: Decodable {
    var presetID: String
    var presetVersion: Int
    var sourceLabel: String
    var type: CardType
    var word: String?
    var reading: String?
    var kanji: String?
    var meaning: String
    var onyomi: String?
    var kunyomi: String?
    var example: String

    var definition: PresetCardDefinition {
        let fields: [(name: String, value: String)]
        switch type {
        case .word:
            fields = [
                ("word", word ?? ""),
                ("reading", reading ?? ""),
                ("meaning", meaning),
                ("example", example),
            ]
        case .kanji:
            fields = [
                ("kanji", kanji ?? ""),
                ("meaning", meaning),
                ("onyomi", onyomi ?? ""),
                ("kunyomi", kunyomi ?? ""),
                ("example", example),
            ]
        }

        return PresetCardDefinition(
            presetID: presetID,
            type: type,
            sourceLabel: sourceLabel,
            fields: fields
        )
    }
}
