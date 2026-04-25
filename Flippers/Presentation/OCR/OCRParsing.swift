import Foundation
import CoreGraphics

// MARK: - Extracted word candidate

struct OCRWord: Identifiable {
    let id = UUID()
    var kanji: String      // 한자 단어
    var reading: String    // 요미가나
    var meaning: String    // 한국어 뜻
    var isSelected: Bool = true
}

struct OCRTextBlock {
    var text: String
    var x: CGFloat
    var y: CGFloat
}

enum OCRRowParser {
    static func parse(blocks: [OCRTextBlock]) -> [OCRWord] {
        let normalizedBlocks = blocks.compactMap(ocrNormalize)
        let sorted = normalizedBlocks.sorted {
            abs($0.y - $1.y) < 0.02 ? $0.x < $1.x : $0.y > $1.y
        }

        var rows: [[OCRTextBlock]] = []
        for block in sorted {
            if let last = rows.last, abs(last[0].y - block.y) <= 0.02 {
                rows[rows.count - 1].append(block)
            } else {
                rows.append([block])
            }
        }

        return rows.compactMap(ocrParseRow)
    }
}

private func ocrParseRow(_ row: [OCRTextBlock]) -> OCRWord? {
    let sortedRow = row.sorted { $0.x < $1.x }

    let studyWordCandidates = sortedRow.enumerated().filter { _, block in
        ocrIsStudyWordLike(block.text)
    }
    let readingCandidates = sortedRow.enumerated().filter { _, block in
        ocrIsReadingLike(block.text)
    }
    let meaningCandidates = sortedRow.enumerated().filter { _, block in
        ocrIsMeaningLike(block.text)
    }

    guard let wordIndex = studyWordCandidates.first?.offset else {
        return nil
    }

    let kanji = sortedRow[wordIndex].text
    let trailingBlocks = sortedRow.enumerated()
        .filter { $0.offset > wordIndex }
        .map(\.element)

    if !trailingBlocks.isEmpty,
       readingCandidates.isEmpty,
       meaningCandidates.isEmpty,
       trailingBlocks.allSatisfy({ ocrIsStudyWordLike($0.text) }) {
        return nil
    }

    let reading = ocrJoin(
        readingCandidates
            .filter { $0.offset > wordIndex }
            .map(\.element.text)
    )

    var meaningSegments = meaningCandidates
        .filter { $0.offset > wordIndex }
        .map(\.element.text)

    if meaningSegments.isEmpty {
        let remaining = trailingBlocks.compactMap { block -> String? in
            guard !ocrIsReadingLike(block.text) else { return nil }
            return block.text
        }
        meaningSegments = remaining
    }

    return OCRWord(
        kanji: kanji,
        reading: reading,
        meaning: ocrJoin(meaningSegments)
    )
}

private func ocrNormalize(_ block: OCRTextBlock) -> OCRTextBlock? {
    let text = block.text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !text.isEmpty, !ocrIsCheckbox(text) else { return nil }
    return OCRTextBlock(text: text, x: block.x, y: block.y)
}

private func ocrJoin(_ parts: [String]) -> String {
    parts
        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty }
        .joined(separator: " ")
}

private func ocrIsStudyWordLike(_ text: String) -> Bool {
    ocrContainsJapanese(text) && !ocrContainsHangul(text)
}

private func ocrIsReadingLike(_ text: String) -> Bool {
    ocrContainsKana(text) && !ocrContainsKanji(text) && !ocrContainsHangul(text)
}

private func ocrIsMeaningLike(_ text: String) -> Bool {
    if ocrContainsHangul(text) {
        return true
    }
    return ocrContainsLatin(text) && !ocrContainsJapanese(text)
}

private func ocrIsCheckbox(_ text: String) -> Bool {
    guard let first = text.first else { return false }
    return ["口", "□", "■", "✓", "✔"].contains(first)
}

private func ocrContainsHangul(_ text: String) -> Bool {
    text.unicodeScalars.contains { (0xAC00...0xD7A3).contains($0.value) }
}

private func ocrContainsKana(_ text: String) -> Bool {
    text.unicodeScalars.contains {
        (0x3040...0x309F).contains($0.value) || (0x30A0...0x30FF).contains($0.value)
    }
}

private func ocrContainsKanji(_ text: String) -> Bool {
    text.unicodeScalars.contains { (0x4E00...0x9FFF).contains($0.value) }
}

private func ocrContainsJapanese(_ text: String) -> Bool {
    ocrContainsKanji(text) || ocrContainsKana(text)
}

private func ocrContainsLatin(_ text: String) -> Bool {
    text.unicodeScalars.contains {
        (0x0041...0x005A).contains($0.value) || (0x0061...0x007A).contains($0.value)
    }
}
