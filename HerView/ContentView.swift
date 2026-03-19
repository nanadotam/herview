//
//  ContentView.swift
//  HerView
//
//  Created by Nana Amoako on 19/03/2026.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var viewModel = SlideshowViewModel()

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)

            PhotoManagementView(viewModel: viewModel)
                .tabItem {
                    Label("Photos", systemImage: "photo.fill")
                }
                .tag(1)

            SettingsView(viewModel: viewModel)
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(2)
        }
        .tint(.pink)
    }
}

#Preview {
    ContentView()
}
