import SwiftUI
import SwiftData
import UIKit

/// Sheet for adding a new card or editing an existing one.
struct CardEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \Deck.createdAt) private var decks: [Deck]

    // When editing an existing card pass it here; nil = create new
    var editingCard: Card?

    @State private var selectedType: CardType = .word
    @State private var selectedDeck: Deck?
    @State private var selectedSection: DeckSection?
    @State private var fieldValues: [String: String] = [:]
    @State private var showAddDeck = false
    @State private var newDeckName = ""
    @State private var showAddSection = false
    @State private var newSectionName = ""

    var body: some View {
        NavigationStack {
            Form {
                // Card type picker
                Section("카드 유형") {
                    Picker("유형", selection: $selectedType) {
                        ForEach(CardType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: selectedType) { _, _ in
                        fieldValues.removeAll()
                    }
                }

                // Dynamic fields based on card type
                Section("카드 내용") {
                    ForEach(selectedType.templateFields, id: \.name) { field in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(fieldLabel(field.name))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            TextField(field.placeholder, text: binding(for: field.name))
                                .font(field.name == "word" || field.name == "kanji"
                                      ? .title2.bold() : .body)
                        }
                        .padding(.vertical, 2)
                    }
                }

                // Deck & Section picker
                Section("덱 / 섹션") {
                    if decks.isEmpty {
                        Button("새 덱 만들기") { showAddDeck = true }
                    } else {
                        Picker("덱", selection: $selectedDeck) {
                            Text("선택 안 함").tag(Optional<Deck>.none)
                            ForEach(decks) { deck in
                                Text(deck.name).tag(Optional(deck))
                            }
                        }
                        .onChange(of: selectedDeck) { _, _ in selectedSection = nil }

                        if let deck = selectedDeck, !deck.sections.isEmpty {
                            Picker("섹션", selection: $selectedSection) {
                                Text("선택 안 함").tag(Optional<DeckSection>.none)
                                ForEach(deck.sections.sorted(by: { $0.name < $1.name })) { sec in
                                    Text(sec.name).tag(Optional(sec))
                                }
                            }
                        }

                        if selectedDeck != nil {
                            Button("새 섹션 만들기") {
                                newSectionName = ""
                                showAddSection = true
                            }
                            .font(.footnote)
                        }

                        Button("새 덱 만들기") { showAddDeck = true }
                            .font(.footnote)
                    }
                }
            }
            .navigationTitle(editingCard == nil ? "카드 추가" : "카드 편집")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") { save() }
                        .bold()
                        .disabled(!isValid)
                }
            }
            .alert("새 섹션", isPresented: $showAddSection) {
                TextField("섹션 이름", text: $newSectionName)
                Button("만들기") { createSection() }
                Button("취소", role: .cancel) {}
            }
            .alert("새 덱", isPresented: $showAddDeck) {
                TextField("덱 이름", text: $newDeckName)
                Button("만들기") { createDeck() }
                Button("취소", role: .cancel) {}
            }
            .onAppear { populateIfEditing() }
        }
    }

    // MARK: - Helpers

    private func binding(for key: String) -> Binding<String> {
        Binding(
            get: { fieldValues[key] ?? "" },
            set: { fieldValues[key] = $0 }
        )
    }

    private func fieldLabel(_ name: String) -> String {
        switch name {
        case "word":    return "단어 / 漢字"
        case "kanji":   return "漢字"
        case "reading": return "読み方"
        case "meaning": return "의미 / Meaning"
        case "example": return "예문（선택）"
        case "onyomi":  return "音読み"
        case "kunyomi": return "訓読み"
        default:        return name
        }
    }

    private var isValid: Bool {
        let primaryKey = selectedType == .word ? "word" : "kanji"
        return !(fieldValues[primaryKey] ?? "").trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func populateIfEditing() {
        guard let card = editingCard else { return }
        selectedType    = card.type
        selectedDeck    = card.deck
        selectedSection = card.section
        for field in card.fields {
            fieldValues[field.fieldName] = field.fieldValue
        }
    }

    private func save() {
        if let card = editingCard {
            updateCard(card)
        } else {
            createCard()
        }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        dismiss()
    }

    private func createCard() {
        let card = Card(type: selectedType, createdSource: .manual)
        card.deck    = selectedDeck
        card.section = selectedSection
        modelContext.insert(card)

        insertFields(into: card)

        let state = SRSState()
        state.card = card
        modelContext.insert(state)
    }

    private func updateCard(_ card: Card) {
        card.type    = selectedType
        card.deck    = selectedDeck
        card.section = selectedSection

        // Remove old fields and replace
        for field in card.fields { modelContext.delete(field) }
        card.fields.removeAll()
        insertFields(into: card)
    }

    private func insertFields(into card: Card) {
        for (index, template) in selectedType.templateFields.enumerated() {
            let value = fieldValues[template.name]?.trimmingCharacters(in: .whitespaces) ?? ""
            guard !value.isEmpty else { continue }
            let field = CardField(fieldName: template.name, fieldValue: value, sortOrder: index)
            field.card = card
            modelContext.insert(field)
        }
    }

    private func createDeck() {
        guard !newDeckName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let deck = Deck(name: newDeckName.trimmingCharacters(in: .whitespaces))
        modelContext.insert(deck)
        selectedDeck = deck
        newDeckName = ""
    }

    private func createSection() {
        guard let deck = selectedDeck else { return }
        let trimmed = newSectionName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let section = DeckSection(name: trimmed)
        section.deck = deck
        modelContext.insert(section)
        selectedSection = section
        newSectionName = ""
    }
}
