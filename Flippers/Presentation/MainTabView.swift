import SwiftUI
import SwiftData

struct MainTabView: View {
    @Environment(AuthViewModel.self) private var authViewModel

    var body: some View {
        TabView {
            StudyView()
                .tabItem {
                    Label("학습", systemImage: "brain.head.profile")
                }

            CardsView()
                .tabItem {
                    Label("카드", systemImage: "rectangle.stack")
                }

            OverviewView()
                .tabItem {
                    Label("개요", systemImage: "chart.bar.xaxis")
                }

            OCRView()
                .tabItem {
                    Label("OCR", systemImage: "doc.viewfinder")
                }
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            if let message = authViewModel.configurationMessage {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "icloud.slash")
                        .foregroundStyle(.orange)
                    Text(message)
                        .font(.footnote)
                        .multilineTextAlignment(.leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.secondarySystemBackground))
                .overlay(alignment: .bottom) {
                    Divider()
                }
            }
        }
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [
            User.self, Deck.self, DeckSection.self, Card.self,
            CardField.self, SRSState.self, ReviewLog.self, OCRSource.self,
        ], inMemory: true)
}
