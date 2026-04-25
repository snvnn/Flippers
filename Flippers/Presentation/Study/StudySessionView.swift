import SwiftUI
import SwiftData

struct StudySessionView: View {
    @Environment(\.modelContext) private var modelContext

    let card: Card
    let session: StudySession

    var body: some View {
        VStack(spacing: 0) {
            StudyProgressView(session: session)

            Spacer()

            StudyFlashcardView(
                card: card,
                session: session,
                onRate: rateCard
            )
            .padding(.horizontal, 24)

            StudyReadingHintButton(card: card, session: session)
                .padding(.top, 16)

            if session.isFlipped {
                StudySwipeHintView()
                    .padding(.horizontal, 48)
                    .padding(.top, 6)
                    .transition(.opacity)
            }

            Spacer()

            if session.isFlipped {
                StudyRatingButtons(onRate: rateCard)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            } else {
                Color.clear
                    .frame(height: 120)
            }
        }
    }

    private func rateCard(_ rating: Rating) {
        session.rate(rating, card: card, context: modelContext)
    }
}

private struct StudyProgressView: View {
    let session: StudySession

    var body: some View {
        let total = session.totalCount
        let done = session.completedCount
        let progress = total > 0 ? Double(done) / Double(total) : 0

        VStack(spacing: 6) {
            HStack {
                Text("残り \(session.queue.count)枚")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                HStack(spacing: 4) {
                    Circle()
                        .fill(.green)
                        .frame(width: 6, height: 6)
                    Text("\(done) 完了")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 24)

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(.systemFill))
                        .frame(height: 4)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.accentColor)
                        .frame(width: geometry.size.width * progress, height: 4)
                        .animation(.easeInOut(duration: 0.4), value: progress)
                }
            }
            .frame(height: 4)
            .padding(.horizontal, 24)
        }
        .padding(.top, 12)
        .padding(.bottom, 8)
    }
}

private struct StudyFlashcardView: View {
    let card: Card
    let session: StudySession
    let onRate: (Rating) -> Void

    var body: some View {
        ZStack {
            CardFaceView(card: card, isFront: true)
                .rotation3DEffect(
                    .degrees(session.isFlipped ? 180 : 0),
                    axis: (x: 0, y: 1, z: 0)
                )
                .opacity(session.isFlipped ? 0 : 1)

            CardFaceView(card: card, isFront: false, showReading: session.showReading)
                .rotation3DEffect(
                    .degrees(session.isFlipped ? 0 : -180),
                    axis: (x: 0, y: 1, z: 0)
                )
                .opacity(session.isFlipped ? 1 : 0)
        }
        .animation(.spring(duration: 0.45), value: session.isFlipped)
        .onTapGesture {
            if !session.isFlipped {
                session.flip()
            }
        }
        .onLongPressGesture(minimumDuration: 0.5) {
            withAnimation(.easeInOut(duration: 0.2)) {
                session.showReading.toggle()
            }
        }
        .gesture(
            DragGesture()
                .onChanged { value in
                    guard session.isFlipped else { return }
                    session.dragOffset = value.translation.width
                }
                .onEnded { value in
                    guard session.isFlipped else { return }
                    let threshold: CGFloat = 80
                    if value.translation.width > threshold {
                        onRate(.good)
                    } else if value.translation.width < -threshold {
                        onRate(.again)
                    } else {
                        withAnimation {
                            session.dragOffset = 0
                        }
                    }
                }
        )
        .offset(x: session.isFlipped ? session.dragOffset * 0.4 : 0)
    }
}

private struct StudyReadingHintButton: View {
    let card: Card
    let session: StudySession

    var body: some View {
        let hasReading = card.readingValue != nil

        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                session.showReading.toggle()
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: session.showReading ? "eye.slash" : "eye")
                    .font(.caption)
                Text(session.showReading ? "발음 숨기기" : "길게 눌러 발음 표시")
                    .font(.caption)
            }
            .foregroundStyle(.secondary)
            .padding(.vertical, 8)
            .padding(.horizontal, 14)
            .background(Color(.secondarySystemBackground), in: Capsule())
        }
        .opacity(hasReading ? 1 : 0)
        .disabled(!hasReading)
    }
}

private struct StudySwipeHintView: View {
    var body: some View {
        HStack {
            Label("Again", systemImage: "arrow.left")
            Spacer()
            Label("Good", systemImage: "arrow.right")
        }
        .font(.caption2)
        .foregroundStyle(Color(.quaternaryLabel))
    }
}

private struct StudyRatingButtons: View {
    let onRate: (Rating) -> Void

    private let config: [(Rating, Color)] = [
        (.again, .red),
        (.hard, .orange),
        (.good, .green),
        (.easy, .indigo),
    ]

    var body: some View {
        HStack(spacing: 8) {
            ForEach(config, id: \.0) { rating, color in
                Button {
                    onRate(rating)
                } label: {
                    VStack(spacing: 2) {
                        Text(rating.label)
                            .font(.subheadline.bold())
                        Text(rating.sublabel)
                            .font(.caption2)
                            .opacity(0.8)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(color, in: RoundedRectangle(cornerRadius: 12))
                    .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct CardFaceView: View {
    let card: Card
    let isFront: Bool
    var showReading: Bool = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.secondarySystemBackground))
                .shadow(color: .black.opacity(0.12), radius: 12, y: 6)

            if isFront {
                frontContent
            } else {
                backContent
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 320)
    }

    private var frontContent: some View {
        VStack(spacing: 12) {
            Text(deckSectionLabel)
                .font(.caption)
                .foregroundStyle(.tertiary)

            Text(card.primaryDisplayValue)
                .font(.system(size: 64, weight: .bold))
                .minimumScaleFactor(0.5)
                .multilineTextAlignment(.center)

            if showReading, let reading = card.readingValue {
                Text(reading)
                    .font(.title3)
                    .foregroundStyle(Color.accentColor)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }

            Spacer()

            Text("탭하여 뒤집기")
                .font(.caption2)
                .foregroundStyle(Color(.quaternaryLabel))
        }
        .padding(28)
    }

    private var backContent: some View {
        VStack(spacing: 16) {
            Text(card.type == .word ? "의미 · Meaning" : "상세 · Details")
                .font(.caption)
                .foregroundStyle(.tertiary)

            switch card.type {
            case .word:
                wordBackContent
            case .kanji:
                kanjiBackContent
            }
        }
        .padding(28)
    }

    private var wordBackContent: some View {
        VStack(spacing: 10) {
            Text(card.primaryDisplayValue)
                .font(.system(size: 40, weight: .bold))
            if let reading = card.readingValue {
                Text(reading)
                    .font(.title3)
                    .foregroundStyle(Color.accentColor)
            }
            if let meaning = card.meaningValue {
                Text(meaning)
                    .font(.title2)
                    .multilineTextAlignment(.center)
            }
            if let example = card.field(named: "example") {
                Text(example)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .italic()
                    .multilineTextAlignment(.center)
                    .padding(.top, 4)
            }
        }
    }

    private var kanjiBackContent: some View {
        VStack(spacing: 10) {
            Text(card.primaryDisplayValue)
                .font(.system(size: 56, weight: .bold))
            if let meaning = card.meaningValue {
                Text(meaning)
                    .font(.title3)
                    .multilineTextAlignment(.center)
            }
            HStack(spacing: 32) {
                VStack(spacing: 4) {
                    Text("音読み")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(card.field(named: "onyomi") ?? "—")
                        .font(.body.bold())
                }
                VStack(spacing: 4) {
                    Text("訓読み")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(card.field(named: "kunyomi") ?? "—")
                        .font(.body.bold())
                }
            }
            .padding(.top, 4)
        }
    }

    private var deckSectionLabel: String {
        [card.deck?.name, card.section?.name]
            .compactMap { $0 }
            .joined(separator: " · ")
    }
}
