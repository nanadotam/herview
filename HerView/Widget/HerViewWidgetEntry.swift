import WidgetKit
import Foundation

struct HerViewEntry: TimelineEntry {
    let date: Date
    let photoIdentifier: String?
    let photoImage: Data?  // Store image as Data for widget rendering
}

struct SimplePlaceholderEntry: TimelineEntry {
    let date: Date
}
