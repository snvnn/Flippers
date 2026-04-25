import SwiftUI
import SwiftData

@Observable
@MainActor
final class StudySession {
    private(set) var queue: [Card] = []
    private(set) var completedCount: Int = 0
    var isFlipped: Bool = false
    var showReading: Bool = false
    var dragOffset: CGFloat = 0
    var ratingBreakdown: [Rating: Int] = [:]

    var currentCard: Card? { queue.first }
    var totalCount: Int { completedCount + queue.count }
    var isDone: Bool { queue.isEmpty && completedCount > 0 }

    func flip() {
        withAnimation(.spring(duration: 0.45)) {
            isFlipped = true
        }
    }

    func start(cards: [Card]) {
        queue = cards
        completedCount = 0
        isFlipped = false
        showReading = false
        dragOffset = 0
        ratingBreakdown = [:]
    }

    func rate(_ rating: Rating, card: Card, context: ModelContext) {
        guard queue.first?.id == card.id else { return }

        let state: SRSState
        if let existing = card.srsState {
            state = existing
        } else {
            let newState = SRSState()
            newState.card = card
            context.insert(newState)
            state = newState
        }

        let output = SRSEngine.calculate(input: state.toInput(), rating: rating)
        state.applyOutput(output)

        let log = ReviewLog(rating: rating)
        log.card = card
        context.insert(log)

        ratingBreakdown[rating, default: 0] += 1
        queue.removeFirst()

        if output.requeueDelay != nil {
            queue.append(card)
        } else {
            completedCount += 1
        }

        withAnimation(.spring(duration: 0.3)) {
            isFlipped = false
            showReading = false
            dragOffset = 0
        }
    }
}
