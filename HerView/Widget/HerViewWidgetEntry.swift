import WidgetKit
import Foundation

struct HerViewEntry: TimelineEntry {
    let date: Date
    let photoIdentifier: String?
}

struct SimplePlaceholderEntry: TimelineEntry {
    let date: Date
}
