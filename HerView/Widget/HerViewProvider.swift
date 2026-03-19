import WidgetKit
import SwiftUI
import Photos

struct HerViewProvider: TimelineProvider {
    private let appGroupID = "group.com.herview.app"

    func placeholder(in context: Context) -> HerViewEntry {
        HerViewEntry(date: Date(), photoIdentifier: nil, photoImage: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (HerViewEntry) -> Void) {
        let photos = loadPhotoIdentifiers()
        var imageData: Data? = nil

        if let firstPhoto = photos.first {
            imageData = loadImageData(for: firstPhoto, maxSize: 500)
        }

        let entry = HerViewEntry(
            date: Date(),
            photoIdentifier: photos.first,
            photoImage: imageData
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<HerViewEntry>) -> Void) {
        let photos = loadPhotoIdentifiers()
        let settings = loadSettings()
        let interval = settings.intervalSeconds

        guard !photos.isEmpty else {
            let entry = HerViewEntry(date: Date(), photoIdentifier: nil, photoImage: nil)
            let timeline = Timeline(entries: [entry], policy: .never)
            completion(timeline)
            return
        }

        var entries: [HerViewEntry] = []
        var date = Date.now

        // Generate up to 12 entries for smoother rotation
        for i in 0..<min(photos.count, 12) {
            let index = settings.shuffleEnabled ? Int.random(in: 0..<photos.count) : i % photos.count
            let photoID = photos[index]
            let imageData = loadImageData(for: photoID, maxSize: 800)

            entries.append(HerViewEntry(
                date: date,
                photoIdentifier: photoID,
                photoImage: imageData
            ))
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

    private func loadImageData(for localIdentifier: String, maxSize: CGFloat) -> Data? {
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [localIdentifier], options: nil)
        guard let asset = fetchResult.firstObject else { return nil }

        let options = PHImageRequestOptions()
        options.isSynchronous = true
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .fast

        var resultData: Data? = nil

        PHImageManager.default().requestImage(
            for: asset,
            targetSize: CGSize(width: maxSize, height: maxSize),
            contentMode: .aspectFill,
            options: options
        ) { image, _ in
            if let image = image,
               let data = image.jpegData(compressionQuality: 0.8) {
                resultData = data
            }
        }

        return resultData
    }
}
