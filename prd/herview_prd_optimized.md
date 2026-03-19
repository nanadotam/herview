# PRODUCT REQUIREMENTS DOCUMENT
## HerView — Personal Photo Widget

**Version**: 1.0 MVP  
**Platform**: iOS 16+  
**Tech Stack**: SwiftUI · WidgetKit · PHPhotoLibrary · SwiftData · AppStorage

---

## Vision

A private, ambient iOS app + widget that rotates a curated set of photos on your home screen and lock screen — no accounts, no social layer, just her face, always present.

---

## Problem Statement

No app offers a simple, private, one-sided photo presence experience. Existing solutions (Locket, etc.) require mutual participation and social infrastructure. HerView is personal, offline, and instant.

---

## Target User

People in relationships who want passive, ambient connection — not communication.

---

## MVP Feature Set

### 1. Photo Selection
- `PHPickerViewController` for native photo access (read-only, no duplication)
- Multi-select with live preview
- Add/remove photos at any time
- Store `localIdentifier` references, not raw image data

### 2. Slideshow Engine
- Auto-rotate on configurable interval
- Default: 60 seconds
- Options: 10s · 30s · 1 min · 5 min · Custom
- Modes: Sequential · Shuffle
- Shuffle respects recency (avoid immediate repeats)

### 3. Widget Display
- **Sizes**: Small (1×1) · Medium (2×1) · Large (2×2)
- **Lock screen**: Rectangular accessory widget (iOS 16+)
- Current photo renders with `ContainerRelativeShape` fill
- Crop modes: Fill · Fit
- Optional filters: None · Grayscale · Warm · Cool

### 4. Settings
- Interval control
- Shuffle toggle
- Crop mode
- Filter picker
- "Add Widget" walkthrough (inline guide with screenshots)

### 5. Persistence & Reliability
- `SwiftData` for `PhotoItem` model (iOS 17) / `UserDefaults` + `FileManager` fallback (iOS 16)
- `@AppStorage` for all settings primitives
- Full offline operation
- Graceful handling of deleted/revoked photos

---

## Technical Architecture

### App Target
```
HerView/
├── HerViewApp.swift              @main, modelContainer setup
├── ContentView.swift             Root tab/nav container
├── Features/
│   ├── PhotoPicker/
│   │   ├── PhotoPickerView.swift
│   │   └── PhotoPickerViewModel.swift
│   ├── Preview/
│   │   ├── SlideshowPreviewView.swift
│   │   └── SlideshowEngine.swift
│   └── Settings/
│       └── SettingsView.swift
├── Models/
│   ├── PhotoItem.swift           @Model (SwiftData)
│   └── SlideshowSettings.swift  Codable struct
├── Services/
│   └── PhotoLibraryService.swift PHPhotoLibrary wrapper
└── Shared/
    └── ImageCache.swift
```

### Widget Extension Target
```
HerViewWidget/
├── HerViewWidget.swift           Widget bundle
├── HerViewWidgetEntry.swift      TimelineEntry
├── HerViewProvider.swift         TimelineProvider
└── HerViewWidgetView.swift       Widget view (small/medium/large)
```

### Data Models

```swift
// PhotoItem.swift
@Model
class PhotoItem {
    var id: UUID
    var localIdentifier: String   // PHAsset local ID
    var sortOrder: Int
    var dateAdded: Date

    init(localIdentifier: String, sortOrder: Int) {
        self.id = UUID()
        self.localIdentifier = localIdentifier
        self.sortOrder = sortOrder
        self.dateAdded = .now
    }
}
```

```swift
// SlideshowSettings.swift — stored via @AppStorage
struct SlideshowSettings: Codable {
    var intervalSeconds: Double = 60
    var shuffleEnabled: Bool = false
    var cropMode: CropMode = .fill
    var filter: PhotoFilter = .none
}

enum CropMode: String, Codable, CaseIterable { case fill, fit }
enum PhotoFilter: String, Codable, CaseIterable { case none, grayscale, warm, cool }
```

### WidgetKit Timeline Strategy

```swift
// HerViewProvider.swift
struct HerViewProvider: TimelineProvider {
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        let photos = loadPhotoIdentifiers()     // read from shared AppGroup UserDefaults
        let settings = loadSettings()
        let interval = settings.intervalSeconds

        var entries: [HerViewEntry] = []
        var date = Date.now

        // Preload up to 8 entries (WidgetKit recommends ≤12)
        for i in 0..<min(photos.count, 8) {
            let index = settings.shuffleEnabled ? photos.indices.randomElement()! : i % photos.count
            entries.append(HerViewEntry(date: date, photoIdentifier: photos[index]))
            date = date.addingTimeInterval(interval)
        }

        // Reload after last entry so it never goes stale
        completion(Timeline(entries: entries, policy: .atEnd))
    }
}
```

**App Group**: Both app and widget extension share an App Group (`group.com.yourname.herview`) to pass photo identifiers and settings via `UserDefaults(suiteName:)`.

### Image Loading in Widget

```swift
func loadImage(for identifier: String) -> UIImage? {
    let options = PHImageRequestOptions()
    options.isSynchronous = true
    options.deliveryMode = .highQualityFormat
    options.resizeMode = .fast

    var result: UIImage?
    PHImageManager.default().requestImage(
        for: asset,
        targetSize: CGSize(width: 400, height: 400),
        contentMode: .aspectFill,
        options: options
    ) { image, _ in result = image }
    return result
}
```

> **Important**: Widget image loading must be synchronous. `isSynchronous = true` is required.

---

## Permissions & Info.plist

```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>HerView needs access to your photos to display them in your widget.</string>
```

No other permissions required.

---

## Shared App Group Setup

1. In Xcode: both targets → Signing & Capabilities → Add Capability → App Groups
2. Create group ID: `group.com.yourname.herview`
3. Use `UserDefaults(suiteName: "group.com.yourname.herview")` in both targets for settings + photo ID array

---

## Edge Cases & Handling

| Scenario | Handling |
|----------|----------|
| Photo deleted from library | Skip asset, show next. Log missing IDs. Clean up on next app open. |
| Photo library permission revoked | Show permission prompt in app. Widget shows placeholder. |
| 0 photos selected | Widget shows empty state illustration + "Open HerView" deeplink |
| 1000+ photos | Cap widget preload at 8 entries. PHImageManager handles memory. |
| iOS widget refresh limits | iOS throttles refreshes — exact interval not guaranteed. Widget reloads `.atEnd`. Minimum effective interval ~15 min in background; foreground app changes trigger immediate reload via `WidgetCenter.shared.reloadAllTimelines()` |

---

## Screens (MVP)

1. **Home** — Slideshow preview, Edit Photos button, Settings button, widget install guide CTA
2. **Photo Picker** — PHPickerViewController sheet, confirm selection
3. **Settings** — Interval, shuffle, crop mode, filter

---

## Non-Goals (MVP)

- No messaging or social features
- No accounts or login
- No cloud sync
- No iCloud backup of photos (only identifiers are stored)
- No Android

---

## V1.1 Roadmap

- Smart shuffle (recency-weighted)
- Time-based sets (morning / evening photos)
- Favorite / pin a photo
- Fade transition duration control
- iCloud sync of settings + photo selection

---

## Performance Targets

| Metric | Target |
|--------|--------|
| Widget render time | < 300ms |
| App cold launch | < 1.5s |
| Peak memory (widget) | < 30MB |
| Photo load (widget) | < 200ms |

---

## Definition of Done (MVP)

- [ ] Photos selectable from library
- [ ] Widget cycles photos on configured interval
- [ ] Small, medium, large widget sizes render correctly
- [ ] Settings persist across launches and widget reloads
- [ ] App stable with 0 critical crashes on Xcode Organizer
- [ ] Widget correctly uses shared App Group data
- [ ] Deleted photo handled gracefully
- [ ] TestFlight build passes on iPhone 14 and iPhone 16
