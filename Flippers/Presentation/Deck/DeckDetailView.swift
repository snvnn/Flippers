import SwiftUI
import SwiftData

struct DeckDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Bindable var deck: Deck

    @State private var showAddSection = false
    @State private var newSectionName = ""
    @State private var showEditDeckName = false
    @State private var editedDeckName = ""
    @State private var showDeleteDeck = false
    @State private var selectedSection: DeckSection?

    private var sortedSections: [DeckSection] {
        deck.sections.sorted { $0.name < $1.name }
    }

    private var unsectionedCards: [Card] {
        deck.cards.filter { $0.section == nil }
    }

    var body: some View {
        List {
            // All cards (unsectioned)
            if !unsectionedCards.isEmpty {
                Section("섹션 없음") {
                    NavigationLink {
                        SectionCardsView(deck: deck, section: nil)
                    } label: {
                        SectionRowView(
                            name: "전체 카드",
                            cardCount: unsectionedCards.count,
                            dueCount: unsectionedCards.filter { card in
                                guard let state = card.srsState else { return false }
                                return state.dueDate <= Date()
                            }.count
                        )
                    }
                }
            }

            // Sections
            Section("섹션") {
                if sortedSections.isEmpty {
                    Text("섹션이 없습니다.\n아래 + 버튼으로 추가하세요.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                } else {
                    ForEach(sortedSections) { section in
                        NavigationLink {
                            SectionCardsView(deck: deck, section: section)
                        } label: {
                            SectionRowView(
                                name: section.name,
                                cardCount: section.cards.count,
                                dueCount: section.cards.filter { card in
                                    guard let state = card.srsState else { return false }
                                    return state.dueDate <= Date()
                                }.count
                            )
                        }
                    }
                    .onDelete(perform: deleteSections)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(deck.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        editedDeckName = deck.name
                        showEditDeckName = true
                    } label: {
                        Label("덱 이름 편집", systemImage: "pencil")
                    }
                    Button {
                        newSectionName = ""
                        showAddSection = true
                    } label: {
                        Label("섹션 추가", systemImage: "plus.circle")
                    }
                    Divider()
                    Button(role: .destructive) {
                        showDeleteDeck = true
                    } label: {
                        Label("덱 삭제", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .alert("섹션 추가", isPresented: $showAddSection) {
            TextField("섹션 이름", text: $newSectionName)
            Button("추가") { addSection() }
            Button("취소", role: .cancel) {}
        }
        .alert("덱 이름 편집", isPresented: $showEditDeckName) {
            TextField("덱 이름", text: $editedDeckName)
            Button("저장") { saveDeckName() }
            Button("취소", role: .cancel) {}
        }
        .confirmationDialog("덱을 삭제하시겠습니까?", isPresented: $showDeleteDeck, titleVisibility: .visible) {
            Button("삭제", role: .destructive) { deleteDeck() }
            Button("취소", role: .cancel) {}
        } message: {
            let cardCount = deck.cards.count
            if cardCount > 0 {
                Text("'\(deck.name)' 덱과 카드 \(cardCount)장이 함께 삭제됩니다. 이 작업은 되돌릴 수 없습니다.")
            } else {
                Text("'\(deck.name)' 덱이 삭제됩니다. 이 작업은 되돌릴 수 없습니다.")
            }
        }
    }

    // MARK: - Actions

    private func addSection() {
        let trimmed = newSectionName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let section = DeckSection(name: trimmed)
        section.deck = deck
        modelContext.insert(section)
        newSectionName = ""
    }

    private func deleteSections(at offsets: IndexSet) {
        for index in offsets {
            let section = sortedSections[index]
            modelContext.delete(section)
        }
    }

    private func saveDeckName() {
        let trimmed = editedDeckName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        deck.name = trimmed
    }

    private func deleteDeck() {
        modelContext.delete(deck)
        dismiss()
    }
}

// MARK: - Section Row

private struct SectionRowView: View {
    let name: String
    let cardCount: Int
    let dueCount: Int

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.headline)
                Text("\(cardCount)장")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if dueCount > 0 {
                Text("\(dueCount) due")
                    .font(.caption.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.red.opacity(0.12), in: Capsule())
                    .foregroundStyle(.red)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Section Cards View

struct SectionCardsView: View {
    @Environment(\.modelContext) private var modelContext

    let deck: Deck
    let section: DeckSection?

    @State private var showAddCard = false

    private var filteredCards: [Card] {
        if let section {
            return deck.cards.filter { $0.section?.id == section.id }
                .sorted { $0.createdAt > $1.createdAt }
        } else {
            return deck.cards.filter { $0.section == nil }
                .sorted { $0.createdAt > $1.createdAt }
        }
    }

    var body: some View {
        List {
            if filteredCards.isEmpty {
                Text("카드가 없습니다.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 16)
                    .listRowBackground(Color.clear)
            } else {
                ForEach(filteredCards) { card in
                    CardRowItem(card: card)
                }
                .onDelete { offsets in
                    for index in offsets {
                        modelContext.delete(filteredCards[index])
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(section?.name ?? "전체 카드")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAddCard = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddCard) {
            CardEditView()
        }
    }
}

// MARK: - Card Row Item

private struct CardRowItem: View {
    let card: Card

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(card.primaryDisplayValue)
                    .font(.headline)
                Spacer()
                if let status = card.srsState?.status {
                    SRSStatusBadge(status: status)
                }
            }
            if let meaning = card.meaningValue {
                Text(meaning)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 2)
    }
}
