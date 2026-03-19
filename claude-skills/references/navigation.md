# Navigation in SwiftUI

## NavigationStack (iOS 16+) — Use This

`NavigationView` is deprecated. Always use `NavigationStack`.

### Basic Push Navigation

```swift
struct ContentView: View {
    var body: some View {
        NavigationStack {
            List(items) { item in
                NavigationLink(item.title, value: item)
            }
            .navigationTitle("Items")
            .navigationDestination(for: Item.self) { item in
                ItemDetailView(item: item)
            }
        }
    }
}
```

### Programmatic Navigation with Typed Routes

```swift
// Define all routes as an enum
enum Route: Hashable {
    case detail(id: UUID)
    case settings
    case profile(username: String)
}

struct RootView: View {
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            HomeView(path: $path)
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .detail(let id):
                        DetailView(id: id)
                    case .settings:
                        SettingsView()
                    case .profile(let username):
                        ProfileView(username: username)
                    }
                }
        }
    }
}

// Navigate from anywhere:
Button("Open Settings") {
    path.append(Route.settings)
}

// Pop to root:
path.removeLast(path.count)
```

## Tab Bar Navigation

```swift
struct AppTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                HomeView()
                    .navigationTitle("Home")
            }
            .tabItem { Label("Home", systemImage: "house.fill") }
            .tag(0)

            NavigationStack {
                SearchView()
                    .navigationTitle("Search")
            }
            .tabItem { Label("Search", systemImage: "magnifyingglass") }
            .tag(1)

            NavigationStack {
                ProfileView()
                    .navigationTitle("Profile")
            }
            .tabItem { Label("Profile", systemImage: "person.fill") }
            .tag(2)
        }
    }
}
```

## Sheets and Modals

```swift
// Sheet (slides up from bottom)
@State private var showSheet = false

.sheet(isPresented: $showSheet) {
    MySheetView()
        .presentationDetents([.medium, .large])  // half-height or full
        .presentationDragIndicator(.visible)
}

// Full screen cover
.fullScreenCover(isPresented: $showFullScreen) {
    FullScreenView()
}

// Sheet with item binding (preferred pattern)
@State private var selectedItem: Item?

.sheet(item: $selectedItem) { item in
    ItemEditView(item: item)
}

// Dismiss from inside a sheet
struct SheetView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Button("Close") { dismiss() }
    }
}
```

## Alerts and Confirmation Dialogs

```swift
// Simple alert
.alert("Delete Item?", isPresented: $showAlert) {
    Button("Delete", role: .destructive) { deleteItem() }
    Button("Cancel", role: .cancel) { }
} message: {
    Text("This cannot be undone.")
}

// Confirmation dialog (action sheet on iPhone)
.confirmationDialog("Choose Action", isPresented: $showDialog, titleVisibility: .visible) {
    Button("Share") { share() }
    Button("Edit") { edit() }
    Button("Delete", role: .destructive) { delete() }
    Button("Cancel", role: .cancel) { }
}
```

## Toolbar Items

```swift
.toolbar {
    ToolbarItem(placement: .topBarTrailing) {
        Button("Add", systemImage: "plus") {
            showAddSheet = true
        }
    }
    ToolbarItem(placement: .topBarLeading) {
        EditButton()  // built-in edit toggle for Lists
    }
    ToolbarItem(placement: .bottomBar) {
        Button("Filter") { showFilter() }
    }
}
```

## Navigation Bar Customization

```swift
.navigationTitle("My App")
.navigationBarTitleDisplayMode(.large)       // .inline for small title
.navigationBarBackButtonHidden(true)          // hide back button
.toolbar(.hidden, for: .navigationBar)        // hide the whole bar
```

## Deep Linking (URL Schemes)

```swift
@main
struct MyApp: App {
    @State private var path = NavigationPath()

    var body: some Scene {
        WindowGroup {
            RootView(path: $path)
        }
        .onOpenURL { url in
            // Parse url and push appropriate route
            if let route = Route(from: url) {
                path.append(route)
            }
        }
    }
}
```
