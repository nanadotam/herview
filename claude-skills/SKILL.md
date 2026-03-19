---
name: ios-swiftui
description: Build, scaffold, architect, and debug iOS apps using Swift and SwiftUI in Xcode. Use this skill whenever the user asks to build an iOS app, write SwiftUI views or components, set up an Xcode project, implement navigation, add data persistence, make network calls, or do anything related to Apple platform development. Also triggers on mentions of Xcode, Swift, SwiftUI, UIKit, NavigationStack, @State, @Observable, SwiftData, Core Data, SF Symbols, or any iOS/iPadOS/macOS/watchOS feature. When in doubt, use this skill — it is the go-to for all things iOS.
---

# iOS App Development with SwiftUI & Xcode

A comprehensive skill for building production-quality iOS apps using Swift and SwiftUI.

## Workflow Decision Tree

When given an iOS task, decide which reference file to load first:

| Task | Load |
|------|------|
| Starting a new project / setting up Xcode | `references/project-setup.md` |
| Writing views, layouts, components | `references/swiftui-fundamentals.md` |
| State, ViewModels, data flow | `references/state-and-architecture.md` |
| Navigation, tabs, sheets, deep links | `references/navigation.md` |
| Persisting data (SwiftData, CoreData, UserDefaults) | `references/data-persistence.md` |
| Networking, REST APIs, async/await | `references/networking.md` |
| Performance, debugging, testing | `references/best-practices.md` |

Load **only the relevant file(s)**. For full app scaffolding, load `project-setup.md` + `state-and-architecture.md` together.

---

## Core Principles (Always Apply)

1. **SwiftUI-first**: Default to SwiftUI. Only suggest UIKit when there is a concrete missing API (e.g., `UIActivityViewController`, complex `UICollectionView` layouts).
2. **Modern APIs**: Use `NavigationStack` (not `NavigationView`), `@Observable` (not `ObservableObject` unless targeting iOS 16), `SwiftData` (not Core Data unless targeting iOS 16).
3. **MVVM**: Keep Views dumb — no business logic, no network calls inside `body`. Logic lives in ViewModels or Services.
4. **Previews**: Always include `#Preview { }` blocks so views are previewable. This is Apple's core development loop.
5. **SF Symbols**: Use SF Symbols (`Image(systemName:)`) for icons — never import unnecessary image assets for standard UI icons.
6. **Lazy containers**: Use `LazyVStack` / `LazyHStack` / `List` for any scrollable list with more than ~20 items.

---

## Quick Reference: Property Wrappers

| Wrapper | Use When |
|---------|----------|
| `@State` | Local value-type state owned by this view |
| `@Binding` | Pass mutable state down to a child view |
| `@StateObject` | Own a reference-type ViewModel (iOS 14-16) |
| `@ObservedObject` | Receive a ViewModel from a parent (iOS 14-16) |
| `@Observable` | Modern ViewModel (iOS 17+, preferred) |
| `@Environment` | Access system/injected values (dismiss, colorScheme) |
| `@AppStorage` | Small values persisted to UserDefaults |
| `@Query` | Query SwiftData models reactively (iOS 17+) |

---

## Minimum Viable SwiftUI View

```swift
import SwiftUI

struct ContentView: View {
    @State private var count = 0

    var body: some View {
        VStack(spacing: 20) {
            Text("Count: \(count)")
                .font(.largeTitle)

            Button("Increment") {
                count += 1
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
```

---

## Common Xcode Shortcuts

| Action | Shortcut |
|--------|----------|
| Build & Run | `Cmd + R` |
| Build only | `Cmd + B` |
| Refresh Preview | `Opt + Cmd + P` |
| Open quickly | `Cmd + Shift + O` |
| Toggle canvas | `Cmd + Opt + Return` |
| Run tests | `Cmd + U` |
| Clean build folder | `Cmd + Shift + K` |
