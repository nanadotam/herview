# State Management & App Architecture

## MVVM Pattern for SwiftUI

Model → ViewModel → View. Views are pure UI. ViewModels hold logic and state. Models are plain data.

```
┌─────────┐     owns/observes     ┌────────────┐    reads/writes    ┌───────┐
│  View   │ ──────────────────▶  │ ViewModel  │ ────────────────▶ │ Model │
│(SwiftUI)│ ◀──────────────────  │(@Observable)│ ◀──────────────── │(struct)│
└─────────┘     updates UI        └────────────┘    data changes    └───────┘
```

## Modern @Observable (iOS 17+) — Preferred

```swift
import Observation

@Observable
class TaskViewModel {
    var tasks: [Task] = []
    var isLoading = false
    var errorMessage: String?

    private let service = TaskService()

    func loadTasks() async {
        isLoading = true
        defer { isLoading = false }
        do {
            tasks = try await service.fetchAll()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteTask(_ task: Task) {
        tasks.removeAll { $0.id == task.id }
    }
}

// In the View — use @State to own it
struct TaskListView: View {
    @State private var viewModel = TaskViewModel()

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
            } else {
                List(viewModel.tasks) { task in
                    TaskRow(task: task)
                }
            }
        }
        .task { await viewModel.loadTasks() }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
}
```

## Legacy ObservableObject (iOS 14-16)

```swift
class TaskViewModel: ObservableObject {
    @Published var tasks: [Task] = []
    @Published var isLoading = false
}

// In View — @StateObject to OWN, @ObservedObject to RECEIVE
struct TaskListView: View {
    @StateObject private var viewModel = TaskViewModel()  // owns it
    // vs @ObservedObject var viewModel: TaskViewModel    // receives from parent
    ...
}
```

**Rule**: Always `@StateObject` when the view creates the ViewModel. `@ObservedObject` only when the ViewModel is passed in from outside.

## Passing State Down with @Binding

```swift
struct ParentView: View {
    @State private var isToggled = false

    var body: some View {
        ToggleButton(isOn: $isToggled)  // $ passes a Binding
    }
}

struct ToggleButton: View {
    @Binding var isOn: Bool  // two-way connection to parent's state

    var body: some View {
        Button(isOn ? "ON" : "OFF") {
            isOn.toggle()
        }
    }
}
```

## Environment — Injecting Shared Dependencies

```swift
// Define a key
struct UserServiceKey: EnvironmentKey {
    static let defaultValue = UserService()
}

extension EnvironmentValues {
    var userService: UserService {
        get { self[UserServiceKey.self] }
        set { self[UserServiceKey.self] = newValue }
    }
}

// Inject at root
ContentView()
    .environment(\.userService, UserService())

// Consume anywhere deep in the tree
struct ProfileView: View {
    @Environment(\.userService) private var userService
}
```

## When to Use Each Pattern

| Need | Solution |
|------|----------|
| Simple local UI state (toggle, text input) | `@State` |
| Share state with a direct child view | `@Binding` |
| Screen-level business logic + state | `@Observable` ViewModel |
| App-wide shared state (auth, user) | `@Observable` + `.environment()` |
| Small persistent settings | `@AppStorage` |
| Database queries | `@Query` (SwiftData) |

## Avoiding Common Mistakes

```swift
// WRONG — modifying state directly in body causes infinite loop
var body: some View {
    count = 0  // ❌ never mutate state here
    return Text("\(count)")
}

// WRONG — @StateObject on a passed-in ViewModel reinitializes it
struct ChildView: View {
    @StateObject var viewModel: ParentViewModel  // ❌ use @ObservedObject
}

// WRONG — heavy computation in body
var body: some View {
    let result = items.filter { ... }.sorted { ... }  // ❌ move to ViewModel
    return List(result) { ... }
}

// RIGHT — move computation out of body
var body: some View {
    List(viewModel.filteredItems) { ... }  // ✅ ViewModel does the work
}
```

## App-Level Architecture Pattern

```swift
// Single source of truth at app level
@Observable
class AppState {
    var currentUser: User?
    var isAuthenticated: Bool { currentUser != nil }
}

@main
struct MyApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            if appState.isAuthenticated {
                MainTabView()
            } else {
                LoginView()
            }
        }
        .environment(appState)
    }
}
```
