# HerView iOS App - Implementation Guide

## Overview

HerView is a personal photo widget app that displays rotating photos on your iOS home screen. This implementation follows the PRD architecture and SwiftUI best practices.

## Project Structure

```
HerView/
├── HerViewApp.swift              # Main app entry point with onboarding
├── ContentView.swift              # Tab navigation (Home, Photos, Settings)
├── Models/
│   ├── PhotoItem.swift           # SwiftData model (iOS 17+)
│   └── SlideshowSettings.swift    # Settings struct with enums
├── Services/
│   └── PhotoLibraryService.swift  # PHPhotoLibrary wrapper
├── ViewModels/
│   └── SlideshowViewModel.swift    # Main state management
├── Features/
│   ├── OnboardingView.swift       # First-launch onboarding
│   ├── HomeView.swift             # Main home screen
│   ├── PhotoPickerView.swift      # Photo selection UI
│   ├── PhotoManagementView.swift   # Photo list with swipe-to-delete
│   ├── SettingsView.swift         # Settings configuration
│   └── WidgetGuideView.swift      # Widget installation guide
└── Widget/
    ├── HerViewWidget.swift        # Widget bundle definition
    ├── HerViewProvider.swift      # TimelineProvider
    ├── HerViewWidgetEntry.swift   # Widget data model
    └── HerViewWidgetView.swift    # Widget UI
```

## Key Features Implemented

### 1. **Onboarding**
- First-launch experience with hero gradient
- Explains the app concept: "She's always with you"
- One-tap "Get Started" button

### 2. **Home Screen**
- Slideshow preview showing current photo
- Quick stats (photo count, interval)
- Widget installation guide CTA
- Active widget display with shuffle status

### 3. **Photo Management**
- Multi-photo picker from Photo Library
- Add/remove photos easily
- Swipe-to-delete gestures
- Visual indicator for currently displayed photo
- Support for 100+ photos (lazy loaded in widget)

### 4. **Settings**
- **Interval Control**: 10s, 30s, 1 min, 5 min options
- **Playback**: Shuffle toggle, Loop toggle
- **Display**: Crop mode (Fill/Fit), Filters (None, B&W, Warm, Cool)
- **About**: Rate, Feedback, Privacy links

### 5. **Widget Integration**
- Small (1×1), Medium (2×1), Large (2×2) sizes
- Uses WidgetKit TimelineProvider
- Shared App Group for data exchange
- Auto-refreshes on interval changes
- Graceful handling of missing photos

## Setup Instructions

### Step 1: App Group Configuration

1. Open `HerView.xcodeproj` in Xcode
2. Select the **HerView** target (app)
3. Go to **Signing & Capabilities**
4. Click **+ Capability** → Search for **App Groups**
5. Add App Group ID: `group.com.herview.app`
6. Repeat for any widget extension target

**Note**: The `appGroupID` in code files is hardcoded as `"group.com.herview.app"`. Update if you change this.

### Step 2: Photo Library Permissions

Add to `Info.plist`:
```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>HerView needs access to your photos to display them in your widget.</string>
```

### Step 3: Widget Extension Setup (In Xcode)

If you haven't created a Widget Extension target yet:

1. File → New → Target
2. Choose **Widget Extension**
3. Name: `HerViewWidget`
4. Set the host app to `HerView`
5. Do **NOT** include a configuration intent initially
6. In the new target's `Info.plist`, add App Group ID: `group.com.herview.app`
7. Replace the auto-generated widget files with the files in `HerView/Widget/`

### Step 4: Build & Run

1. Select the **HerView** scheme
2. Build & run on a device or simulator (iOS 16+)
3. Go through onboarding
4. Add photos from Photo Library
5. Configure settings as desired

### Step 5: Add Widget to Home Screen

1. Long-press home screen
2. Tap **+** button
3. Search for "HerView"
4. Select widget size
5. Tap "Add Widget"

## Data Persistence

### App Group UserDefaults

Both the app and widget extension share data via:
```swift
UserDefaults(suiteName: "group.com.herview.app")
```

**Keys Stored:**
- `photoIdentifiers` → Array of selected PHAsset local IDs
- `slideshowSettings` → JSON-encoded SlideshowSettings

### SwiftData (Optional - iOS 17+)

The `PhotoItem` model is defined but currently not required for MVP. Can be used in v1.1 for additional metadata or sync features.

## Important Notes

### Image Loading in Widget

- Widget uses **synchronous** image loading with `isSynchronous = true`
- This is required for WidgetKit to render timely
- Images are loaded at 400×400 resolution (adjust based on widget size)
- The app doesn't cache images; PhotosLib handles it

### Performance Targets

| Metric | Target |
|--------|--------|
| Widget render time | < 300ms |
| App cold launch | < 1.5s |
| Photo load (widget) | < 200ms |
| Peak memory | < 30MB |

### Permissions Handling

- App requests photo library access on-demand
- Widget shows empty state if access denied
- Gracefully handles deleted/revoked photos (skips them, shows next)

## Testing Checklist

- [ ] Onboarding shows on first launch
- [ ] Can add 5+ photos from Photo Library
- [ ] Widget preview shows current photo
- [ ] Settings save and persist
- [ ] Widget displays on home screen
- [ ] Photos rotate on configured interval
- [ ] Shuffle mode randomizes order
- [ ] Swipe-to-delete removes photos
- [ ] App handles deleted photos gracefully
- [ ] Works offline

## Troubleshooting

### Widget not updating
1. Check App Group ID matches in both targets
2. Ensure `UserDefaults(suiteName:)` uses correct group ID
3. Try `WidgetCenter.shared.reloadAllTimelines()` from app

### Photos not showing
1. Verify NSPhotoLibraryUsageDescription in Info.plist
2. Grant photo library permission in Settings → HerView → Photos
3. Check if assets still exist in Photo Library

### App Group sync issues
1. Both targets must have identical App Group capability
2. Verify bundle identifiers match expected pattern
3. Try clean build folder (Cmd+Shift+K)

## Next Steps (V1.1+)

- [ ] iCloud sync of settings + photo selection
- [ ] Smart shuffle (recency-weighted)
- [ ] Time-based photo sets (morning/evening)
- [ ] Favorite/pin photo feature
- [ ] Custom interval input
- [ ] Lock screen widget support

## Questions?

Refer to:
- `prd/herview_prd_optimized.md` - Complete technical specification
- `prd/herview_screens.html` - Visual mockups
- `claude-skills/SKILL.md` - iOS development best practices
