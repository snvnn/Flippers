//
//  ContentView.swift
//  Flippers
//
//  Created by 윤현 on 3/30/26.
//

import SwiftUI

struct ContentView: View {
    @State private var authViewModel = AuthViewModel()

    var body: some View {
        Group {
            if authViewModel.shouldShowAuthentication {
                AuthView()
                    .environment(authViewModel)
            } else {
                MainTabView()
                    .environment(authViewModel)
            }
        }
    }
}

#Preview {
    ContentView()
}
