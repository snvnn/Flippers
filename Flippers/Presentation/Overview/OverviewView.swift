import SwiftUI
import SwiftData

struct OverviewView: View {
    @Query private var allCards: [Card]
    @Query(sort: \Deck.name) private var decks: [Deck]
    @Query(sort: \ReviewLog.reviewedAt, order: .reverse) private var recentLogs: [ReviewLog]

    private var today: Date { Calendar.current.startOfDay(for: Date()) }

    private var totalCount: Int { allCards.count }

    private var dueCount: Int {
        allCards.filter { card in
            guard let state = card.srsState else { return false }
            return state.dueDate <= Date()
        }.count
    }

    private var learningCount: Int {
        allCards.filter { $0.srsState?.status == .learning }.count
    }

    private var avgEase: Double {
        guard !allCards.isEmpty else { return 0 }
        let total = allCards.compactMap { $0.srsState?.ease }.reduce(0, +)
        let count = allCards.compactMap { $0.srsState?.ease }.count
        return count > 0 ? total / Double(count) : 0
    }

    private var statusDistribution: [(SRSStatus, Int, Color)] {
        [
            (.new,        allCards.filter { $0.srsState?.status == .new }.count,        .indigo),
            (.learning,   allCards.filter { $0.srsState?.status == .learning }.count,   .orange),
            (.review,     allCards.filter { $0.srsState?.status == .review }.count,     .green),
            (.relearning, allCards.filter { $0.srsState?.status == .relearning }.count, .red),
        ]
    }

    var body: some View {
        NavigationStack {
            List {
                // Stats cards
                Section {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        StatCard(
                            title: "총 카드",
                            subtitle: "Total Cards",
                            value: "\(totalCount)",
                            icon: "rectangle.stack.fill",
                            color: .blue
                        )
                        StatCard(
                            title: "오늘 복습",
                            subtitle: "Due Today",
                            value: "\(dueCount)",
                            icon: "clock.fill",
                            color: .orange
                        )
                        StatCard(
                            title: "학습 중",
                            subtitle: "Learning",
                            value: "\(learningCount)",
                            icon: "graduationcap.fill",
                            color: .purple
                        )
                        StatCard(
                            title: "평균 Ease",
                            subtitle: "Avg Ease",
                            value: String(format: "%.2f", avgEase),
                            icon: "chart.line.uptrend.xyaxis",
                            color: .green
                        )
                    }
                    .listRowInsets(.init())
                    .listRowBackground(Color.clear)
                }

                // SRS Distribution
                Section("SRS 상태 분포") {
                    HStack(spacing: 8) {
                        ForEach(statusDistribution, id: \.0) { status, count, color in
                            VStack(spacing: 6) {
                                Circle()
                                    .fill(color)
                                    .frame(width: 10, height: 10)
                                Text("\(count)")
                                    .font(.title3.bold())
                                Text(status.rawValue.capitalized)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(color.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .listRowInsets(.init())
                    .listRowBackground(Color.clear)
                }

                // Deck list
                Section("デッキ一覧") {
                    if decks.isEmpty {
                        Text("덱이 없습니다. 카드 탭에서 만들어보세요.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(decks) { deck in
                            NavigationLink(destination: DeckDetailView(deck: deck)) {
                                DeckRowView(deck: deck)
                            }
                        }
                    }
                }

                // Recent activity
                let todayLogs = recentLogs.filter {
                    Calendar.current.isDateInToday($0.reviewedAt)
                }
                if !todayLogs.isEmpty {
                    Section("오늘 복습 기록") {
                        ForEach(todayLogs.prefix(10)) { log in
                            HStack {
                                Text(log.card?.primaryDisplayValue ?? "—")
                                    .font(.body.bold())
                                Spacer()
                                RatingBadge(rating: log.rating)
                                Text(log.reviewedAt, style: .time)
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("概要")
        }
    }
}

// MARK: - Stat Card

private struct StatCard: View {
    let title: String
    let subtitle: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                    .font(.subheadline)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(value)
                .font(.largeTitle.bold())
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Deck Row

private struct DeckRowView: View {
    let deck: Deck

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(deck.name)
                    .font(.headline)
                if !deck.sections.isEmpty {
                    Text(deck.sections.sorted { $0.name < $1.name }.map { $0.name }.joined(separator: " · "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(deck.cards.count) cards")
                    .font(.subheadline)
                let due = deck.dueCount
                if due > 0 {
                    Text("\(due) due")
                        .font(.caption.bold())
                        .foregroundStyle(.red)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Rating Badge

struct RatingBadge: View {
    let rating: Rating

    var body: some View {
        Text(rating.label)
            .font(.caption2.bold())
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(ratingColor.opacity(0.15), in: Capsule())
            .foregroundStyle(ratingColor)
    }

    private var ratingColor: Color {
        switch rating {
        case .again: return .red
        case .hard:  return .orange
        case .good:  return .green
        case .easy:  return .indigo
        }
    }
}
