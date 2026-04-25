import SwiftUI
import SwiftData

private enum StudyDeckSelection {
    case all
    case deck(UUID)

    init(deckID: UUID?) {
        if let deckID {
            self = .deck(deckID)
        } else {
            self = .all
        }
    }

    var deckID: UUID? {
        switch self {
        case .all:
            return nil
        case .deck(let deckID):
            return deckID
        }
    }
}

struct StudyView: View {
    @Query private var allCards: [Card]
    @Query(sort: \Deck.name) private var decks: [Deck]
    @AppStorage("hasSeenRatingGuide") private var hasSeenRatingGuide = false
    @State private var session = StudySession()
    @State private var selectedDeckID: UUID?
    @State private var showAddCard = false
    @State private var showFilterAlert = false
    @State private var pendingDeckSelection: StudyDeckSelection?
    @State private var showRatingGuide = false

    private var dueCards: [Card] {
        let now = Date()
        return allCards.filter { card in
            if let state = card.srsState {
                guard state.dueDate <= now else { return false }
            }
            if let deckID = selectedDeckID {
                return card.deck?.id == deckID
            }
            return true
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if session.isDone {
                    SessionCompleteView(
                        total: session.completedCount,
                        breakdown: session.ratingBreakdown,
                        onRestart: { session.start(cards: dueCards) }
                    )
                } else if let card = session.currentCard {
                    StudySessionView(card: card, session: session)
                } else {
                    EmptyStudyView(
                        hasNoCards: allCards.isEmpty,
                        onAddCard: { showAddCard = true }
                    )
                }
            }
            .onAppear(perform: startInitialSessionIfNeeded)
            .sheet(isPresented: $showAddCard) {
                CardEditView()
            }
            .overlay {
                if showRatingGuide {
                    RatingGuideOverlay {
                        hasSeenRatingGuide = true
                        showRatingGuide = false
                    }
                    .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.25), value: showRatingGuide)
            .alert("학습 세션 초기화", isPresented: $showFilterAlert) {
                Button("초기화", role: .destructive, action: applyPendingDeckFilter)
                Button("취소", role: .cancel, action: clearPendingDeckFilter)
            } message: {
                Text("덱을 변경하면 현재 진행 중인 세션이 초기화됩니다. 계속할까요?")
            }
            .navigationTitle("학습")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    StudyDeckFilterMenu(
                        decks: decks,
                        selectedDeckID: selectedDeckID,
                        onSelect: requestDeckFilter
                    )
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if session.totalCount > 0 {
                        Text("\(session.completedCount)/\(session.totalCount)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private func startInitialSessionIfNeeded() {
        guard session.queue.isEmpty, session.completedCount == 0, !dueCards.isEmpty else { return }
        session.start(cards: dueCards)
        if !hasSeenRatingGuide {
            showRatingGuide = true
        }
    }

    private func requestDeckFilter(_ deckID: UUID?) {
        let isSessionActive = session.totalCount > 0 && !session.isDone
        if isSessionActive {
            pendingDeckSelection = StudyDeckSelection(deckID: deckID)
            showFilterAlert = true
            return
        }
        applyDeckFilter(deckID)
    }

    private func applyPendingDeckFilter() {
        applyDeckFilter(pendingDeckSelection?.deckID)
        pendingDeckSelection = nil
    }

    private func clearPendingDeckFilter() {
        pendingDeckSelection = nil
    }

    private func applyDeckFilter(_ deckID: UUID?) {
        selectedDeckID = deckID
        session.start(cards: dueCards)
    }
}
