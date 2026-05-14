//
//  FlippersApp.swift
//  Flippers
//
//  Created by 윤현 on 3/30/26.
//

import SwiftUI
import SwiftData

@main
struct FlippersApp: App {

    private let container: ModelContainer

    init() {
        _ = FirebaseBootstrap.configureIfAvailable()
        let schema = Schema([
            User.self,
            Deck.self,
            DeckSection.self,
            Card.self,
            CardField.self,
            SRSState.self,
            ReviewLog.self,
            OCRSource.self,
        ])
        #if DEBUG
        let config = ModelConfiguration(schema: schema)
        #else
        let config = ModelConfiguration(schema: schema, cloudKitDatabase: .automatic)
        #endif
        do {
            container = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("ModelContainer 생성 실패: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(container)
        }
    }
}
