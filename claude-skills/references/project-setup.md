# Xcode Project Setup & Structure

## Creating a New Project

1. Open Xcode → **File → New → Project**
2. Select **iOS → App** → Next
3. Fill in:
   - **Product Name**: Your app name (e.g., `TaskTracker`)
   - **Organization Identifier**: `com.yourname` (reverse-domain, e.g., `com.nana`)
   - **Interface**: SwiftUI
   - **Language**: Swift
4. Uncheck **Core Data** unless you need it
5. Check **Include Tests** for production apps; uncheck for rapid prototyping

## Default Files Explained

| File | Purpose |
|------|---------|
| `MyAppApp.swift` | `@main` entry point — the app's root |
| `ContentView.swift` | First screen shown when the app launches |
| `Assets.xcassets` | Images, colors, app icons |
| `Preview Content/` | Assets used only during Xcode Previews — excluded from App Store build |
| `Info.plist` | App permissions, settings, metadata |

## Recommended Folder Structure

### Small App (MVVM by layer)
```
MyApp/
├── MyAppApp.swift
├── ContentView.swift
├── Models/           ← structs, enums representing data
├── Views/
│   ├── Screens/      ← full-screen views
│   └── Components/   ← reusable UI pieces (buttons, cards, etc.)
├── ViewModels/       ← @Observable classes
├── Services/         ← networking, location, notifications
├── Persistence/      ← SwiftData / Core Data / UserDefaults wrappers
├── Extensions/       ← Swift type extensions
└── Constants/        ← app-wide colors, strings, config
```

### Medium/Large App (by feature)
```
MyApp/
├── MyAppApp.swift
├── Core/             ← shared utilities, extensions, base types
├── Features/
│   ├── Home/
│   │   ├── HomeView.swift
│   │   ├── HomeViewModel.swift
│   │   └── HomeModel.swift
│   ├── Profile/
│   └── Settings/
└── Resources/
    └── Assets.xcassets
```

## App Entry Point

```swift
import SwiftUI

@main
struct MyAppApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

For SwiftData, inject the model container here:

```swift
@main
struct MyAppApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Task.self, User.self])
    }
}
```

## iOS Version Targeting

- **iOS 17+**: Use `@Observable`, `SwiftData`, `@Query` — modern, clean
- **iOS 16**: Use `ObservableObject`/`@Published`, `NavigationStack`, Core Data
- **iOS 15 and below**: Use `NavigationView` (deprecated but functional), UIKit bridges

To set deployment target: Project navigator → select project → General → Minimum Deployments.

## SF Symbols Usage

SF Symbols are Apple's built-in icon library (5,800+ icons, free). Always prefer them over imported assets for UI icons.

```swift
Image(systemName: "heart.fill")       // filled heart
Image(systemName: "star")              // outline star
Image(systemName: "chevron.right")     // disclosure arrow
Image(systemName: "plus.circle.fill")  // add button
```

Browse symbols: Download **SF Symbols app** from Apple's developer site.
