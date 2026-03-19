import SwiftUI
import SwiftData

@Observable
class SlideshowViewModel {
    var currentPhotoIdentifier: String?
    var photoIdentifiers: [String] = []
    var settings: SlideshowSettings = .shared
    var isRunning = false

    private var timer: Timer?
    private let appGroupID = "group.com.herview.app"

    init() {
        loadPhotoIdentifiers()
        loadSettings()
    }

    func startSlideshow() {
        isRunning = true
        scheduleNextPhoto()
    }

    func stopSlideshow() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }

    func updateSettings(_ newSettings: SlideshowSettings) {
        settings = newSettings
        saveSettings()
        if isRunning {
            stopSlideshow()
            startSlideshow()
        }
    }

    private func scheduleNextPhoto() {
        timer?.invalidate()
        showNextPhoto()

        timer = Timer.scheduledTimer(withTimeInterval: settings.intervalSeconds, repeats: true) { [weak self] _ in
            self?.showNextPhoto()
        }
    }

    private func showNextPhoto() {
        guard !photoIdentifiers.isEmpty else {
            currentPhotoIdentifier = nil
            return
        }

        if settings.shuffleEnabled {
            currentPhotoIdentifier = photoIdentifiers.randomElement()
        } else {
            if currentPhotoIdentifier == nil {
                currentPhotoIdentifier = photoIdentifiers.first
            } else if let currentIndex = photoIdentifiers.firstIndex(of: currentPhotoIdentifier!) {
                let nextIndex = (currentIndex + 1) % photoIdentifiers.count
                currentPhotoIdentifier = photoIdentifiers[nextIndex]
            }
        }
    }

    func addPhoto(with localIdentifier: String) {
        if !photoIdentifiers.contains(localIdentifier) {
            photoIdentifiers.append(localIdentifier)
            savePhotoIdentifiers()
        }
    }

    func removePhoto(with localIdentifier: String) {
        photoIdentifiers.removeAll { $0 == localIdentifier }
        if currentPhotoIdentifier == localIdentifier {
            showNextPhoto()
        }
        savePhotoIdentifiers()
    }

    func reorderPhotos(_ newOrder: [String]) {
        photoIdentifiers = newOrder
        savePhotoIdentifiers()
    }

    private func savePhotoIdentifiers() {
        if let defaults = UserDefaults(suiteName: appGroupID) {
            defaults.set(photoIdentifiers, forKey: "photoIdentifiers")
        }
    }

    private func loadPhotoIdentifiers() {
        if let defaults = UserDefaults(suiteName: appGroupID) {
            photoIdentifiers = defaults.stringArray(forKey: "photoIdentifiers") ?? []
        }
    }

    private func saveSettings() {
        if let defaults = UserDefaults(suiteName: appGroupID),
           let encoded = try? JSONEncoder().encode(settings) {
            defaults.set(encoded, forKey: "slideshowSettings")
        }
    }

    private func loadSettings() {
        if let defaults = UserDefaults(suiteName: appGroupID),
           let data = defaults.data(forKey: "slideshowSettings"),
           let decoded = try? JSONDecoder().decode(SlideshowSettings.self, from: data) {
            settings = decoded
        }
    }
}
