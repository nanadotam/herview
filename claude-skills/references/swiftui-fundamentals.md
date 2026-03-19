# SwiftUI Fundamentals

## View Protocol

Every SwiftUI view is a `struct` conforming to `View`, with a `body` computed property:

```swift
struct ProfileCard: View {
    let name: String
    let bio: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(name)
                .font(.headline)
            Text(bio)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    ProfileCard(name: "Nana", bio: "iOS Developer")
        .padding()
}
```

## Layout Containers

### Stacks
```swift
// Vertical
VStack(alignment: .leading, spacing: 16) { ... }

// Horizontal
HStack(alignment: .center, spacing: 8) { ... }

// Depth/overlay
ZStack(alignment: .bottomTrailing) { ... }
```

### Lazy containers (use for lists/grids with many items)
```swift
ScrollView {
    LazyVStack(spacing: 12) {
        ForEach(items) { item in
            ItemRow(item: item)
        }
    }
    .padding()
}
```

### List (system-styled, supports swipe actions)
```swift
List(items) { item in
    ItemRow(item: item)
}
.listStyle(.insetGrouped)

// With swipe to delete:
List {
    ForEach(items) { item in
        Text(item.name)
    }
    .onDelete(perform: deleteItems)
}
```

### Grid
```swift
let columns = [GridItem(.adaptive(minimum: 150))]

ScrollView {
    LazyVGrid(columns: columns, spacing: 12) {
        ForEach(items) { item in
            ItemCard(item: item)
        }
    }
    .padding()
}
```

## Common Views

```swift
// Text
Text("Hello")
    .font(.title)           // .largeTitle .title .title2 .headline .body .caption
    .fontWeight(.bold)
    .foregroundStyle(.blue)
    .lineLimit(2)
    .multilineTextAlignment(.center)

// Image
Image("photo-name")         // from Assets.xcassets
Image(systemName: "star")   // SF Symbol
    .imageScale(.large)
    .symbolRenderingMode(.multicolor)

// Button
Button("Save") { save() }
    .buttonStyle(.borderedProminent)  // .bordered .plain .borderless

// AsyncImage (load from URL)
AsyncImage(url: URL(string: imageURL)) { image in
    image.resizable().scaledToFill()
} placeholder: {
    ProgressView()
}
.frame(width: 80, height: 80)
.clipShape(Circle())

// TextField
TextField("Enter name", text: $name)
    .textFieldStyle(.roundedBorder)
    .keyboardType(.emailAddress)
    .autocorrectionDisabled()

// Toggle
Toggle("Notifications", isOn: $notificationsEnabled)

// Picker
Picker("Color", selection: $selectedColor) {
    ForEach(colors, id: \.self) { Text($0) }
}
.pickerStyle(.segmented)   // .menu .wheel .inline

// Stepper / Slider
Stepper("Quantity: \(qty)", value: $qty, in: 1...10)
Slider(value: $volume, in: 0...1)
```

## Modifiers — Order Matters

Modifiers are applied from inside-out:

```swift
Text("Hello")
    .font(.headline)          // changes text font
    .foregroundStyle(.white)  // changes text color
    .padding(16)              // adds space around text
    .background(.blue)        // fills padded area
    .cornerRadius(10)         // clips the background
    .shadow(radius: 4)        // shadow on the whole thing
```

## Conditional Views

```swift
// If/else in body
var body: some View {
    if isLoggedIn {
        HomeView()
    } else {
        LoginView()
    }
}

// Ternary for simple swaps
Text(isLiked ? "Liked!" : "Like")
    .foregroundStyle(isLiked ? .red : .secondary)

// ViewBuilder with Group
Group {
    if showDetails {
        DetailSection()
    }
}
```

## ForEach

```swift
// With Identifiable models
ForEach(items) { item in
    Text(item.name)
}

// With range
ForEach(0..<5) { i in
    Text("Item \(i)")
}

// With index
ForEach(Array(items.enumerated()), id: \.offset) { index, item in
    Text("\(index + 1). \(item.name)")
}
```

## Custom Modifiers

```swift
struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }
}

// Usage:
Text("Hello").cardStyle()
```

## Spacing & Layout Tips

- Use `Spacer()` to push views apart: `HStack { Text("Left"); Spacer(); Text("Right") }`
- Use `.frame(maxWidth: .infinity)` to stretch a view full width
- Use `.padding(.horizontal, 16)` for standard content margins
- Use `Divider()` for horizontal lines in lists
- Use `.overlay` for badges, indicators on top of views
