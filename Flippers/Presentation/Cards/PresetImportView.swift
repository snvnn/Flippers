import SwiftUI
import SwiftData

struct PresetImportView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query private var allCards: [Card]

    @State private var importMessage: String?

    private let presets = DefaultPresetCatalog.presets

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(presets) { preset in
                        PresetImportRow(
                            preset: preset,
                            installedCount: installedCount(for: preset),
                            onImport: { importPreset(preset) }
                        )
                    }
                } footer: {
                    Text("상용 한자 2136 전체 데이터는 출처와 라이선스 확정 후 같은 import 구조에 실어 교체합니다.")
                }
            }
            .navigationTitle("프리셋 가져오기")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("닫기") { dismiss() }
                }
            }
            .alert("가져오기 완료", isPresented: Binding(
                get: { importMessage != nil },
                set: { if !$0 { importMessage = nil } }
            )) {
                Button("확인") {}
            } message: {
                Text(importMessage ?? "")
            }
        }
    }

    private func installedCount(for preset: PresetDefinition) -> Int {
        let ids = Set(preset.cards.map(\.presetID))
        return allCards.filter { card in
            guard let presetID = card.presetID else { return false }
            return ids.contains(presetID)
        }.count
    }

    private func importPreset(_ preset: PresetDefinition) {
        let result = PresetImportService.importPreset(
            preset,
            into: modelContext,
            existingCards: allCards
        )
        importMessage = "\(result.deckName)에 \(result.createdCount)개를 추가했습니다. 이미 있던 \(result.skippedCount)개는 건너뛰었습니다."
    }
}

private struct PresetImportRow: View {
    let preset: PresetDefinition
    let installedCount: Int
    let onImport: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: preset.id.contains("kanji") ? "character.book.closed" : "text.book.closed")
                    .font(.title2)
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 4) {
                    Text(preset.title)
                        .font(.headline)
                    Text(preset.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(progressText)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }

                Spacer()
            }

            if !preset.isComplete {
                Label("전체 \(preset.expectedCardCount)개 중 현재 \(preset.cards.count)개 샘플 포함", systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }

            Text(preset.sourceNote)
                .font(.caption)
                .foregroundStyle(.secondary)

            Button {
                onImport()
            } label: {
                Label(installedCount == preset.cards.count ? "설치됨" : "가져오기", systemImage: "square.and.arrow.down")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(installedCount == preset.cards.count)
        }
        .padding(.vertical, 8)
    }

    private var progressText: String {
        "\(installedCount)/\(preset.cards.count)개 설치됨"
    }
}
