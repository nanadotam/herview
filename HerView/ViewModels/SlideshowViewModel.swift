import SwiftUI
import SwiftData

@Observable
class SlideshowViewModel {
    var currentPhotoIdentifier: String?
    var photoIdentifiers: [String] = []
    var settings: SlideshowSettings = .shared
    var isRunning = false

    private var timer: Timer?

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
            var updated = photoIdentifiers
            updated.append(localIdentifier)
            photoIdentifiers = updated
            savePhotoIdentifiers()
        }
    }

    func removePhoto(with localIdentifier: String) {
        var updated = photoIdentifiers
        updated.removeAll { $0 == localIdentifier }
        photoIdentifiers = updated
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
        UserDefaults.standard.set(photoIdentifiers, forKey: "photoIdentifiers")
    }

    private func loadPhotoIdentifiers() {
        photoIdentifiers = UserDefaults.standard.stringArray(forKey: "photoIdentifiers") ?? []
    }

    private func saveSettings() {
        if let encoded = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(encoded, forKey: "slideshowSettings")
        }
    }

    private func loadSettings() {
        if let data = UserDefaults.standard.data(forKey: "slideshowSettings"),
           let decoded = try? JSONDecoder().decode(SlideshowSettings.self, from: data) {
            settings = decoded
        }
    }
}
