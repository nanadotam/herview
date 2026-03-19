# SwiftUI Best Practices, Performance & Debugging

## Performance

### Use Lazy Containers for Long Lists
```swift
// BAD — renders all 1000 items at once
ScrollView {
    VStack {
        ForEach(items) { ItemRow(item: $0) }
    }
}

// GOOD — renders only visible items
ScrollView {
    LazyVStack {
        ForEach(items) { ItemRow(item: $0) }
    }
}
```

### Extract Subviews to Limit Re-renders
SwiftUI only re-renders views whose dependencies changed. Extract subviews to isolate updates:

```swift
// BAD — changing `count` re-renders the entire view including the expensive header
var body: some View {
    VStack {
        ExpensiveHeaderView()  // re-renders even if only count changed
        Text("Count: \(count)")
    }
}

// GOOD — ExpensiveHeaderView only re-renders when its own data changes
var body: some View {
    VStack {
        ExpensiveHeaderView()
        CounterView(count: count)
    }
}
```

### Use Equatable to Skip Unnecessary Re-renders
```swift
struct ItemRow: View, Equatable {
    let item: Item
    static func == (lhs: ItemRow, rhs: ItemRow) -> Bool {
        lhs.item.id == rhs.item.id && lhs.item.updatedAt == rhs.item.updatedAt
    }
    // SwiftUI will skip re-rendering if Equatable check returns true
}
```

### Debug Re-renders
```swift
struct ContentView: View {
    var body: some View {
        let _ = Self._printChanges()  // prints which property caused re-render
        return Text("Hello")
    }
}
```

### Keep `body` Lightweight
```swift
// BAD — heavy computation in body
var body: some View {
    List(items.filter { $0.isActive }.sorted { $0.name < $1.name }) { ... }
}

// GOOD — compute in ViewModel, expose a clean property
var body: some View {
    List(viewModel.activeItemsSorted) { ... }
}
```

## Code Quality

### Use @discardableResult for fire-and-forget async
```swift
Button("Refresh") {
    Task { await viewModel.refresh() }  // fire and forget
}
```

### Use `task` modifier instead of `onAppear` for async
```swift
// PREFER — task is async-aware, cancels automatically when view disappears
.task { await viewModel.loadData() }

// AVOID for async work (requires manual Task wrapping)
.onAppear { Task { await viewModel.loadData() } }
```

### Use `.id()` for forcing view recreation
```swift
// Force MyView to fully recreate when selectedID changes
MyView(item: selectedItem)
    .id(selectedItem.id)
```

### Prefer `let` over `var` in Views
SwiftUI views are structs — mark properties `let` unless they need to be `var`.

### Stable IDs in ForEach
```swift
// BAD — using array index as ID causes animation glitches on insert/delete
ForEach(Array(items.enumerated()), id: \.offset) { ... }

// GOOD — use a stable, unique property
ForEach(items, id: \.id) { ... }
// or if Item conforms to Identifiable:
ForEach(items) { ... }
```

## Common Bugs and Fixes

### Preview Crashes
```swift
// Add preview-safe mock data
#Preview {
    TaskListView()
        .modelContainer(for: Task.self, inMemory: true)  // in-memory for previews
}
```

### "Publishing changes from within view updates"
This warning means you're mutating `@Published`/`@State` synchronously in a loop:
```swift
// Fix: dispatch on main queue or restructure logic
DispatchQueue.main.async {
    self.items = newItems
}
// Or in async context:
await MainActor.run { self.items = newItems }
```

### View not updating after data changes
- Ensure the ViewModel uses `@Observable` or `@Published`
- Ensure the view uses `@State` (for `@Observable`) or `@StateObject`/`@ObservedObject`
- If using SwiftData, use `@Query` — never manually hold model arrays

### List row tap area too small
```swift
// Wrap the row content in a NavigationLink or Button with .contentShape
.contentShape(Rectangle())
.onTapGesture { ... }
```

## Accessibility

```swift
Image(systemName: "star.fill")
    .accessibilityLabel("Favorite")

Button("Submit") { submit() }
    .accessibilityHint("Submits the form")

Text("$42.00")
    .accessibilityValue("Forty-two dollars")
```

## App Store Submission Checklist

- [ ] App icon provided in all required sizes (use Asset Catalog, Xcode generates from 1024x1024)
- [ ] Privacy descriptions in `Info.plist` for every permission used (camera, location, etc.)
- [ ] No hardcoded credentials or API keys in source code — use `.xcconfig` or environment variables
- [ ] Test on real device (not just simulator) before submission
- [ ] Set correct bundle ID and version numbers in project settings
- [ ] Review Provisioning Profile and signing certificates in Xcode → Signing & Capabilities
- [ ] Test with slow/offline network conditions

## Privacy Permissions (Info.plist keys)

| Permission | Info.plist Key |
|-----------|----------------|
| Camera | `NSCameraUsageDescription` |
| Photo Library | `NSPhotoLibraryUsageDescription` |
| Location (when in use) | `NSLocationWhenInUseUsageDescription` |
| Location (always) | `NSLocationAlwaysAndWhenInUseUsageDescription` |
| Microphone | `NSMicrophoneUsageDescription` |
| Contacts | `NSContactsUsageDescription` |
| Notifications | Requested programmatically via `UNUserNotificationCenter` |

Always provide a clear, user-facing reason explaining why the app needs the permission.
