import Foundation

enum CropMode: String, Codable, CaseIterable {
    case fill = "Fill"
    case fit = "Fit"
}

enum PhotoFilter: String, Codable, CaseIterable {
    case none = "None"
    case grayscale = "B&W"
    case warm = "Warm"
    case cool = "Cool"
}

struct SlideshowSettings: Codable {
    var intervalSeconds: Double = 60
    var shuffleEnabled: Bool = false
    var cropMode: CropMode = .fill
    var filter: PhotoFilter = .none

    static let shared = SlideshowSettings()
}
