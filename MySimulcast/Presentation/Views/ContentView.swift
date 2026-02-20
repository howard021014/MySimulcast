//
//  ContentView.swift
//  MySimulcast
//
//  Created by Howard tsai on 2026-02-18.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("MySimulcast")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Anime Simulcast Tracker")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Home")
        }
    }
}

#Preview {
    ContentView()
}
