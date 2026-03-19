import SwiftUI
import WidgetKit

struct HerViewWidgetView: View {
    let entry: HerViewEntry
    @Environment(\.widgetFamily) var widgetFamily

    var body: some View {
        ZStack {
            // Background photo
            if let photoData = entry.photoImage,
               let uiImage = UIImage(data: photoData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
            } else {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 1.0, green: 0.52, blue: 0.62),
                        Color(red: 0.97, green: 0.31, blue: 0.62)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }

            // Overlay with app name
            VStack(alignment: .leading) {
                HStack {
                    VStack(alignment: .leading) {
                        Text("HerView")
                            .font(.system(size: widgetFamily == .systemSmall ? 14 : 18, weight: .bold))
                            .foregroundColor(.white)

                        if widgetFamily != .systemSmall {
                            Text("Always with you")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    Spacer()
                }
                .padding(12)

                Spacer()
            }
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.black.opacity(0.4),
                        Color.black.opacity(0.1)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }
        .containerRelativeFrame([.horizontal, .vertical])
    }
}

// MARK: - Widget Definition
// Note: @main removed because widget is in main app bundle
// Widget needs its own target to be the entry point

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
        .description("Display your favorite photo rotating on your home screen. Always with you.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// Widget previews will work once widget files are in a separate Widget Extension target
// For now, test widgets by adding them to your home screen in the simulator
