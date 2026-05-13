import SwiftUI
import SwiftData

struct CardsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Card.createdAt, order: .reverse) private var allCards: [Card]
    @Query(sort: \Deck.name) private var decks: [Deck]

    @State private var searchText = ""
    @State private var selectedDeckID: UUID?
    @State private var showAddCard = false
    @State private var showPresetImport = false
    @State private var editingCard: Card?

    // MARK: - Filtered cards

    private var filteredCards: [Card] {
        allCards.filter { card in
            if let deckID = selectedDeckID, card.deck?.id != deckID { return false }
            if searchText.isEmpty { return true }
            let query = searchText.lowercased()
            return card.fields.contains { $0.fieldValue.lowercased().contains(query) }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Deck filter pills
                deckFilterPills

                // Card list
                List {
                    if filteredCards.isEmpty {
                        emptyState
                    } else {
                        ForEach(filteredCards) { card in
                            CardRowView(card: card)
                                .contentShape(Rectangle())
                                .onTapGesture { editingCard = card }
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        deleteCard(card)
                                    } label: {
                                        Label("삭제", systemImage: "trash")
                                    }
                                }
                        }
                    }
                }
                .listStyle(.plain)
            }
            .searchable(text: $searchText, prompt: "카드 검색… (단어, 의미, 한자)")
            .navigationTitle("カード管理")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showPresetImport = true
                    } label: {
                        Image(systemName: "square.and.arrow.down")
                    }
                    .accessibilityLabel("프리셋 가져오기")
                }
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
            .sheet(isPresented: $showPresetImport) {
                PresetImportView()
            }
            .sheet(item: $editingCard) { card in
                CardEditView(editingCard: card)
            }
        }
    }

    // MARK: - Deck Filter Pills

    private var deckFilterPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterPill(title: "全部", id: nil)
                ForEach(decks) { deck in
                    filterPill(title: deck.name, id: deck.id)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .background(Color(.systemBackground))
    }

    private func filterPill(title: String, id: UUID?) -> some View {
        let isSelected = selectedDeckID == id
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedDeckID = id
            }
        } label: {
            Text(title)
                .font(.subheadline)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(
                    isSelected ? Color.accentColor : Color(.secondarySystemBackground),
                    in: Capsule()
                )
                .foregroundStyle(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        ContentUnavailableView(
            label: {
                Label(
                    searchText.isEmpty ? "카드 없음" : "検索結果なし",
                    systemImage: searchText.isEmpty ? "rectangle.stack.badge.plus" : "magnifyingglass"
                )
            },
            description: {
                Text(searchText.isEmpty ? "프리셋을 가져오거나 오른쪽 위 + 버튼으로 카드를 추가하세요." : "다른 검색어를 시도해보세요.")
            }
        )
        .listRowSeparator(.hidden)
    }

    // MARK: - Delete

    private func deleteCard(_ card: Card) {
        modelContext.delete(card)
    }
}

// MARK: - Card Row

private struct CardRowView: View {
    let card: Card

    var body: some View {
        HStack(spacing: 14) {
            // Primary value + reading
            VStack(alignment: .center, spacing: 2) {
                Text(card.primaryDisplayValue)
                    .font(.title2.bold())
                    .lineLimit(1)
                if let reading = card.readingValue {
                    Text(reading)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 64)

            // Meaning + deck info
            VStack(alignment: .leading, spacing: 3) {
                Text(card.meaningValue ?? "")
                    .font(.subheadline)
                    .lineLimit(1)
                Text([card.deck?.name, card.section?.name].compactMap { $0 }.joined(separator: " · "))
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            // SRS status badge
            if let state = card.srsState {
                VStack(alignment: .trailing, spacing: 3) {
                    SRSStatusBadge(status: state.status)
                    Text("E:\(String(format: "%.1f", state.ease)) I:\(state.interval)d")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.vertical, 6)
    }
}

// MARK: - SRS Status Badge

struct SRSStatusBadge: View {
    let status: SRSStatus

    var body: some View {
        Text(status.rawValue.capitalized)
            .font(.caption2.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(statusColor.opacity(0.15), in: Capsule())
            .foregroundStyle(statusColor)
    }

    private var statusColor: Color {
        switch status {
        case .new:       return .indigo
        case .learning:  return .orange
        case .review:    return .green
        case .relearning: return .red
        }
    }
}
