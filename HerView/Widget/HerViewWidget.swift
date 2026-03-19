import WidgetKit
import SwiftUI

@main
struct HerViewWidget: WidgetBundle {
    var body: some Widget {
        HerViewTimelineWidget()
    }
}

struct HerViewTimelineWidget: Widget {
    let kind: String = "com.herview.widget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HerViewProvider()) { entry in
            HerViewWidgetView(entry: entry)
        }
        .configurationDisplayName("HerView")
        .description("Display your favorite photo rotating on your home screen.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
