# Data Persistence in iOS

## Decision Guide

| Need | Use |
|------|-----|
| 1-2 small values (settings, flags) | `@AppStorage` / `UserDefaults` |
| Structured local database (iOS 17+) | `SwiftData` |
| Structured local database (iOS 16) | `Core Data` |
| Files, images, documents | `FileManager` |
| Secure credentials | `Keychain` |
| Sync across devices | SwiftData + CloudKit |

---

## SwiftData (iOS 17+ — Preferred)

### Define a Model

```swift
import SwiftData

@Model
class Task {
    var title: String
    var isCompleted: Bool
    var createdAt: Date
    var priority: Int

    init(title: String, priority: Int = 0) {
        self.title = title
        self.isCompleted = false
        self.createdAt = .now
        self.priority = priority
    }
}
```

### Set Up Container in App Entry Point

```swift
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Task.self])
    }
}
```

### Query and Mutate in Views

```swift
struct TaskListView: View {
    // Fetch all tasks, sorted by date
    @Query(sort: \Task.createdAt, order: .reverse) var tasks: [Task]
    @Environment(\.modelContext) private var context

    var body: some View {
        List {
            ForEach(tasks) { task in
                HStack {
                    Text(task.title)
                    Spacer()
                    if task.isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                }
                .onTapGesture { task.isCompleted.toggle() }  // SwiftData auto-saves
            }
            .onDelete { offsets in
                offsets.forEach { context.delete(tasks[$0]) }
            }
        }
        .toolbar {
            Button("Add", systemImage: "plus") {
                let task = Task(title: "New Task")
                context.insert(task)
            }
        }
    }
}
```

### Filtering with @Query

```swift
// Filter by predicate
@Query(filter: #Predicate<Task> { $0.isCompleted == false },
       sort: \Task.createdAt) var pendingTasks: [Task]

// Dynamic queries — use in a child view with the filter passed in
struct FilteredList: View {
    @Query var tasks: [Task]

    init(showCompleted: Bool) {
        let completed = showCompleted
        _tasks = Query(filter: #Predicate<Task> { $0.isCompleted == completed })
    }
}
```

### Relationships

```swift
@Model
class Project {
    var name: String
    @Relationship(deleteRule: .cascade) var tasks: [Task] = []

    init(name: String) { self.name = name }
}

@Model
class Task {
    var title: String
    var project: Project?  // inverse relationship auto-detected
    ...
}
```

---

## AppStorage (UserDefaults wrapper)

Best for small primitive values: booleans, strings, integers.

```swift
struct SettingsView: View {
    @AppStorage("isDarkMode") private var isDarkMode = false
    @AppStorage("fontSize") private var fontSize = 16.0
    @AppStorage("username") private var username = ""

    var body: some View {
        Form {
            Toggle("Dark Mode", isOn: $isDarkMode)
            Slider(value: $fontSize, in: 12...24) {
                Text("Font Size: \(Int(fontSize))")
            }
        }
    }
}
```

---

## UserDefaults (programmatic)

```swift
// Save
UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
UserDefaults.standard.set("Nana", forKey: "username")

// Retrieve with default
let seen = UserDefaults.standard.bool(forKey: "hasSeenOnboarding")
let name = UserDefaults.standard.string(forKey: "username") ?? "Guest"

// Save Codable objects
struct Preferences: Codable {
    var theme: String
    var notificationsEnabled: Bool
}

let prefs = Preferences(theme: "dark", notificationsEnabled: true)
let data = try? JSONEncoder().encode(prefs)
UserDefaults.standard.set(data, forKey: "preferences")

// Retrieve Codable
if let data = UserDefaults.standard.data(forKey: "preferences"),
   let prefs = try? JSONDecoder().decode(Preferences.self, from: data) {
    print(prefs.theme)
}
```

---

## FileManager (documents, images)

```swift
// Save data to documents directory
func saveToDocuments(data: Data, filename: String) throws {
    let url = FileManager.default
        .urls(for: .documentDirectory, in: .userDomainMask)[0]
        .appendingPathComponent(filename)
    try data.write(to: url)
}

// Read from documents
func loadFromDocuments(filename: String) throws -> Data {
    let url = FileManager.default
        .urls(for: .documentDirectory, in: .userDomainMask)[0]
        .appendingPathComponent(filename)
    return try Data(contentsOf: url)
}

// Save image
func saveImage(_ image: UIImage, name: String) {
    if let data = image.jpegData(compressionQuality: 0.8) {
        try? saveToDocuments(data: data, filename: "\(name).jpg")
    }
}
```
