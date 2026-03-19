//
//  HerViewApp.swift
//  HerView
//
//  Created by Nana Amoako on 19/03/2026.
//

import SwiftUI
import SwiftData
import Photos

@main
struct HerViewApp: App {
    @State private var hasSeenOnboarding = UserDefaults.standard.bool(forKey: "hasSeenOnboarding")
    @State private var modelContainer: ModelContainer?

    var body: some Scene {
        WindowGroup {
            if hasSeenOnboarding {
                ContentView()
                    .onChange(of: hasSeenOnboarding) { oldValue, newValue in
                        UserDefaults.standard.set(newValue, forKey: "hasSeenOnboarding")
                    }
                    .task {
                        await requestPhotoLibraryAccess()
                    }
            } else {
                OnboardingView(hasSeenOnboarding: $hasSeenOnboarding)
                    .onChange(of: hasSeenOnboarding) { oldValue, newValue in
                        UserDefaults.standard.set(newValue, forKey: "hasSeenOnboarding")
                    }
            }
        }
    }

    private func requestPhotoLibraryAccess() async {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        if status == .notDetermined {
            let _ = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        }
    }
}
