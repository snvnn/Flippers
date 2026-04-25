import SwiftUI

struct StudyDeckFilterMenu: View {
    let decks: [Deck]
    let selectedDeckID: UUID?
    let onSelect: (UUID?) -> Void

    var body: some View {
        Menu {
            Button {
                onSelect(nil)
            } label: {
                if selectedDeckID == nil {
                    Label("전체", systemImage: "checkmark")
                } else {
                    Text("전체")
                }
            }

            ForEach(decks) { deck in
                Button {
                    onSelect(deck.id)
                } label: {
                    if selectedDeckID == deck.id {
                        Label(deck.name, systemImage: "checkmark")
                    } else {
                        Text(deck.name)
                    }
                }
            }
        } label: {
            Label(selectedDeckName, systemImage: "line.3.horizontal.decrease.circle")
        }
    }

    private var selectedDeckName: String {
        guard let selectedDeckID else { return "전체" }
        return decks.first(where: { $0.id == selectedDeckID })?.name ?? "전체"
    }
}

struct EmptyStudyView: View {
    let hasNoCards: Bool
    let onAddCard: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: hasNoCards ? "rectangle.stack.badge.plus" : "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(hasNoCards ? Color.accentColor : .green)

            if hasNoCards {
                Text("카드가 없습니다")
                    .font(.title2.bold())
                Text("첫 번째 카드를 만들어 학습을 시작하세요.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Button(action: onAddCard) {
                    Label("첫 카드 만들기", systemImage: "plus")
                        .font(.body.bold())
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 14))
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 40)
                .padding(.top, 8)
            } else {
                Text("오늘 복습 없음")
                    .font(.title2.bold())
                Text("모든 카드를 복습했습니다.\n내일 다시 확인하세요.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
}

struct SessionCompleteView: View {
    let total: Int
    let breakdown: [Rating: Int]
    let onRestart: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "party.popper.fill")
                .font(.system(size: 64))
                .foregroundStyle(.yellow)

            VStack(spacing: 6) {
                Text("お疲れ様！")
                    .font(.largeTitle.bold())
                Text("오늘 복습 완료!")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 12) {
                ForEach(Rating.allCases, id: \.self) { rating in
                    let count = breakdown[rating, default: 0]
                    VStack(spacing: 4) {
                        Text("\(count)")
                            .font(.title2.bold())
                        Text(rating.label)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(.horizontal, 24)

            Button(action: onRestart) {
                Label("다시 시작", systemImage: "arrow.counterclockwise")
                    .font(.body.bold())
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 14))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 24)
        }
    }
}

struct RatingGuideOverlay: View {
    let onDismiss: () -> Void

    private let items: [(String, Color, String, String)] = [
        ("Again", .red, "もう一度", "틀림 — 곧 다시 출제"),
        ("Hard", .orange, "難しい", "어렵게 맞음 — 짧은 간격"),
        ("Good", .green, "良い", "정확히 기억 — 정상 간격"),
        ("Easy", .indigo, "簡単", "쉽게 기억 — 긴 간격"),
    ]

    var body: some View {
        ZStack {
            Color.black.opacity(0.55)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            VStack(spacing: 20) {
                VStack(spacing: 6) {
                    Text("평가 버튼 안내")
                        .font(.title2.bold())
                    Text("각 버튼을 누르면 다음 복습 시기가 달라집니다")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                VStack(spacing: 10) {
                    ForEach(items, id: \.0) { label, color, sublabel, description in
                        HStack(spacing: 14) {
                            VStack(spacing: 2) {
                                Text(label)
                                    .font(.subheadline.bold())
                                Text(sublabel)
                                    .font(.caption2)
                                    .opacity(0.85)
                            }
                            .frame(width: 64)
                            .padding(.vertical, 10)
                            .background(color, in: RoundedRectangle(cornerRadius: 10))
                            .foregroundStyle(.white)

                            Text(description)
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                            Spacer()
                        }
                    }
                }

                Button(action: onDismiss) {
                    Text("학습 시작")
                        .font(.body.bold())
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 14))
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
            }
            .padding(24)
            .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 20))
            .padding(.horizontal, 24)
        }
    }
}
