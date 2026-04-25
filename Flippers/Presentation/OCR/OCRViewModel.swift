import Foundation
import UIKit
import SwiftData

// MARK: - OCR Step

enum OCRStep {
    case upload
    case scanning
    case review
    case done(Int)
}

// MARK: - ViewModel

@Observable
@MainActor
final class OCRViewModel {
    var step: OCRStep = .upload
    var extractedWords: [OCRWord] = []
    var selectedDeck: Deck?
    var errorMessage: String?
    var enhancementWarning: String?
    var scanningMessage: String = "텍스트 인식 중…"
    
    var selectedWordCount: Int {
        extractedWords.filter(\.isSelected).count
    }

    var savableSelectedWordCount: Int {
        extractedWords.filter { $0.isSelected && isSavable($0) }.count
    }

    var hasInvalidSelectedWords: Bool {
        extractedWords.contains { $0.isSelected && !isSavable($0) }
    }

    var hasIncompleteSelectedWords: Bool {
        extractedWords.contains {
            $0.isSelected && !normalize($0.kanji).isEmpty && (normalize($0.reading).isEmpty || normalize($0.meaning).isEmpty)
        }
    }

    var reviewNoticeMessage: String? {
        if extractedWords.isEmpty {
            return "현재 OCR은 가로형 일본어 단어표 레이아웃에 가장 잘 맞습니다. 다른 레이아웃에서는 결과가 비어 있을 수 있습니다."
        }

        if hasIncompleteSelectedWords {
            return "일부 선택 항목은 읽기 또는 뜻이 비어 있습니다. 저장 전에 수정하거나 선택 해제하세요."
        }

        return nil
    }

    // MARK: - Process image

    /// Vision on-device로 텍스트를 추출한 뒤, 필요할 때만 서버 프록시 뒤의 Claude로 읽기/뜻을 보완한다.
    /// 외부 보완이 꺼져 있거나 프록시 호출에 실패하면 Vision 결과를 그대로 사용한다.
    func processImage(_ image: UIImage, useCloudEnhancement: Bool) async {
        step = .scanning
        errorMessage = nil
        enhancementWarning = nil
        scanningMessage = "텍스트 인식 중…"

        // Step 1: Vision으로 텍스트 추출
        let rawWords = OCRVisionExtractor.extractWords(from: image)

        guard useCloudEnhancement else {
            extractedWords = rawWords
            if rawWords.contains(where: { $0.reading.isEmpty || $0.meaning.isEmpty }) {
                enhancementWarning = "외부 보완이 꺼져 있어 읽기/뜻이 비어있을 수 있습니다."
            }
            step = .review
            return
        }

        // Step 2: 프록시 서버로 읽기/뜻 보완 요청 (실패 시 rawWords 그대로 사용)
        scanningMessage = "읽기 · 뜻 보완 중…"
        do {
            let enhanced = try await ClaudeOCRService.shared.enhanceWords(rawWords)
            extractedWords = enhanced
        } catch {
            // fallback: Vision만으로 추출된 단어 사용 (reading/meaning 비어있을 수 있음)
            extractedWords = rawWords
            enhancementWarning = "서버 보완에 실패했습니다. Vision 결과만 사용합니다. 읽기/뜻이 비어있을 수 있습니다."
        }

        step = .review
    }

    // MARK: - Save selected words as cards

    func saveCards(context: ModelContext) {
        let selected = extractedWords.filter { $0.isSelected }
        guard !selected.isEmpty else { return }
        guard !hasInvalidSelectedWords else {
            errorMessage = "선택한 항목 중 저장할 수 없는 값이 있습니다. 한자, 읽기, 뜻을 확인하거나 선택 해제 후 다시 시도하세요."
            return
        }

        for word in selected {
            let normalizedWord = normalize(word.kanji)
            let normalizedReading = normalize(word.reading)
            let normalizedMeaning = normalize(word.meaning)

            let card = Card(type: .word, createdSource: .ocr)
            card.deck = selectedDeck
            context.insert(card)

            let fieldDefs: [(String, String)] = [
                ("word", normalizedWord),
                ("reading", normalizedReading),
                ("meaning", normalizedMeaning),
            ]
            for (index, (name, value)) in fieldDefs.enumerated() where !value.isEmpty {
                let field = CardField(fieldName: name, fieldValue: value, sortOrder: index)
                field.card = card
                context.insert(field)
            }

            let state = SRSState()
            state.card = card
            context.insert(state)
        }

        step = .done(selected.count)
    }

    func reset() {
        step = .upload
        extractedWords = []
        errorMessage = nil
        enhancementWarning = nil
    }

    func toggleWord(id: UUID) {
        if let index = extractedWords.firstIndex(where: { $0.id == id }) {
            extractedWords[index].isSelected.toggle()
        }
    }

    func selectAll() {
        for i in extractedWords.indices { extractedWords[i].isSelected = true }
    }

    private func isSavable(_ word: OCRWord) -> Bool {
        !normalize(word.kanji).isEmpty && !normalize(word.reading).isEmpty && !normalize(word.meaning).isEmpty
    }

    private func normalize(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
