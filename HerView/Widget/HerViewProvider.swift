import WidgetKit
import SwiftUI

struct HerViewProvider: TimelineProvider {
    private let appGroupID = "group.com.herview.app"

    func placeholder(in context: Context) -> HerViewEntry {
        HerViewEntry(date: Date(), photoIdentifier: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (HerViewEntry) -> Void) {
        let photos = loadPhotoIdentifiers()
        let entry = HerViewEntry(
            date: Date(),
            photoIdentifier: photos.first
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<HerViewEntry>) -> Void) {
        let photos = loadPhotoIdentifiers()
        let settings = loadSettings()
        let interval = settings.intervalSeconds

        guard !photos.isEmpty else {
            let entry = HerViewEntry(date: Date(), photoIdentifier: nil)
            let timeline = Timeline(entries: [entry], policy: .never)
            completion(timeline)
            return
        }

        var entries: [HerViewEntry] = []
        var date = Date.now

        for i in 0..<min(photos.count, 8) {
            let index = settings.shuffleEnabled ? Int.random(in: 0..<photos.count) : i % photos.count
            entries.append(HerViewEntry(date: date, photoIdentifier: photos[index]))
            date = date.addingTimeInterval(interval)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }

    private func loadPhotoIdentifiers() -> [String] {
        guard let defaults = UserDefaults(suiteName: appGroupID) else { return [] }
        return defaults.stringArray(forKey: "photoIdentifiers") ?? []
    }

    private func loadSettings() -> SlideshowSettings {
        guard let defaults = UserDefaults(suiteName: appGroupID),
              let data = defaults.data(forKey: "slideshowSettings"),
              let decoded = try? JSONDecoder().decode(SlideshowSettings.self, from: data) else {
            return SlideshowSettings()
        }
        return decoded
    }
}
