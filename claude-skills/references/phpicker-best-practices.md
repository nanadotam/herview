# PHPickerViewController Best Practices for Production iOS Apps

## Overview

PHPickerViewController is the modern, privacy-first approach to photo selection in iOS 14+. It operates as a separate process, preventing apps from direct photo library access until the user explicitly selects media. This comprehensive guide covers production-ready patterns for SwiftUI integration, performance optimization, error handling, and real-world patterns.

---

## 1. SwiftUI + PHPickerViewController Integration

### Basic Implementation Pattern

The standard approach uses `UIViewControllerRepresentable` to bridge UIKit's PHPickerViewController with SwiftUI:

```swift
import SwiftUI
import PhotosUI

struct PHPickerRepresentable: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    let onComplete: ([PHPickerResult]) -> Void

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.selectionLimit = 0  // Unlimited
        config.preferredAssetRepresentationMode = .current
        config.selection = .ordered  // Maintains selection order

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onComplete: onComplete)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let onComplete: ([PHPickerResult]) -> Void

        init(onComplete: @escaping ([PHPickerResult]) -> Void) {
            self.onComplete = onComplete
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            onComplete(results)
            picker.dismiss(animated: true)
        }
    }
}
```

### Configuration Options (Official Apple API)

Key `PHPickerConfiguration` properties:

| Property | Default | Purpose |
|----------|---------|---------|
| `selectionLimit` | 1 | Number of items user can select (0 = unlimited) |
| `filter` | `.images` | Media type filter (images, videos, livePhotos) |
| `preferredAssetRepresentationMode` | `.automatic` | How to import assets (.current, .compatible, .automatic) |
| `selection` | `.default` | Selection behavior (.default, .ordered) |

See [PHPickerConfiguration | Apple Developer Documentation](https://developer.apple.com/documentation/photosui/phpickerconfiguration-swift.struct)

---

## 2. Handling Photo Selection & Display in SwiftUI

### Proper Data Flow Pattern

```swift
@Observable
class PhotoSelectionViewModel {
    var selectedResults: [PHPickerResult] = []
    var isLoading = false
    var error: PhotoLoadError?

    // Store only the asset identifier (not the full image)
    var photoIdentifiers: [String] = []

    func handlePhotoPicked(_ results: [PHPickerResult]) {
        isLoading = true
        selectedResults = results

        Task {
            defer { isLoading = false }

            for result in results {
                // Store the asset identifier for persistent storage
                if let assetID = result.assetIdentifier {
                    self.photoIdentifiers.append(assetID)
                }
            }
        }
    }
}
```

### Display Selected Photos

```swift
struct PhotoDisplayView: View {
    @State var viewModel: PhotoSelectionViewModel

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())]) {
                ForEach(viewModel.photoIdentifiers, id: \.self) { identifier in
                    PhotoGridItem(identifier: identifier)
                }
            }
        }
    }
}

struct PhotoGridItem: View {
    let identifier: String
    @State private var image: UIImage?
    @State private var isLoading = false

    var body: some View {
        ZStack {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .transition(.opacity)
            } else if isLoading {
                ProgressView()
            } else {
                Color.gray.opacity(0.3)
                    .onAppear { loadImage() }
            }
        }
        .aspectRatio(1, contentMode: .fill)
        .clipped()
    }

    private func loadImage() {
        isLoading = true
        Task {
            let image = await loadPhotoThumbnail(identifier: identifier)
            self.image = image
            self.isLoading = false
        }
    }
}
```

### Key Principles

1. **Store asset identifiers, not images**: Keep only `assetIdentifier` or `localIdentifier` persisted
2. **Load images on-demand**: Use `PHImageManager` with targeted sizes
3. **Handle missing photos**: Check if assets still exist using `checkAssetExists()`
4. **Maintain selection order**: Use `selection: .ordered` in configuration

---

## 3. Loading States & Animations

### Comprehensive Loading State Pattern

```swift
enum PhotoLoadingState {
    case idle
    case selecting
    case processing(progress: Double)
    case error(PhotoLoadError)
    case success

    var isLoading: Bool {
        if case .selecting = self { return true }
        if case .processing = self { return true }
        return false
    }
}

struct PhotoImportView: View {
    @State private var loadingState: PhotoLoadingState = .idle
    @State private var showPicker = false

    var body: some View {
        VStack {
            switch loadingState {
            case .idle:
                Button(action: { showPicker = true }) {
                    Text("Select Photos")
                }

            case .selecting:
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Selecting photos...")
                        .font(.caption)
                        .foregroundColor(.gray)
                }

            case .processing(let progress):
                VStack(spacing: 12) {
                    ProgressView(value: progress) {
                        Text("Importing \(Int(progress * 100))%")
                    }
                }

            case .error(let error):
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.title)
                        .foregroundColor(.red)
                    Text(error.localizedDescription)
                        .font(.caption)
                    Button("Try Again") { showPicker = true }
                }

            case .success:
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Photos imported successfully")
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .sheet(isPresented: $showPicker) {
            PHPickerRepresentable { results in
                handlePhotosSelected(results)
            }
        }
    }

    private func handlePhotosSelected(_ results: [PHPickerResult]) {
        loadingState = .processing(progress: 0)

        Task {
            let total = results.count
            for (index, result) in results.enumerated() {
                // Process each photo
                let progress = Double(index + 1) / Double(total)
                await MainActor.run {
                    loadingState = .processing(progress: progress)
                }
            }

            await MainActor.run {
                loadingState = .success
                try? await Task.sleep(nanoseconds: 1_500_000_000)  // 1.5s
                loadingState = .idle
            }
        }
    }
}
```

### Animation Best Practices

1. **Use `.withAnimation()` for state transitions**:
```swift
withAnimation(.easeInOut(duration: 0.3)) {
    self.loadingState = .processing(progress: 0.5)
}
```

2. **Apply transitions to appear/disappear views**:
```swift
if isLoading {
    ProgressView()
        .transition(.scale.combined(with: .opacity))
}
```

3. **Animate ProgressView**:
```swift
ProgressView(value: progress)
    .animation(.linear(duration: 0.3), value: progress)
```

4. **Keep animations smooth with appropriate durations** (200-500ms typically best for UI feedback)

---

## 4. Photo Persistence & Data Sync

### Using SwiftData for Photo Storage

```swift
import SwiftData

@Model
final class PhotoItem {
    var id: UUID = UUID()
    var localIdentifier: String      // Asset identifier for retrieval
    var sortOrder: Int               // Maintain user order
    var dateAdded: Date = .now

    init(localIdentifier: String, sortOrder: Int) {
        self.localIdentifier = localIdentifier
        self.sortOrder = sortOrder
    }
}
```

### ViewModel Integration

```swift
@Observable
class PhotoLibraryViewModel {
    @ObservationIgnored
    private var modelContext: ModelContext

    var photos: [PhotoItem] = []
    var error: PhotoLoadError?

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadPhotos()
    }

    func addPhotos(_ results: [PHPickerResult]) {
        let currentMax = photos.map(\.sortOrder).max() ?? 0

        for (index, result) in results.enumerated() {
            if let assetID = result.assetIdentifier {
                let photoItem = PhotoItem(
                    localIdentifier: assetID,
                    sortOrder: currentMax + index + 1
                )
                modelContext.insert(photoItem)
                photos.append(photoItem)
            }
        }

        save()
    }

    func removePhoto(_ photoItem: PhotoItem) {
        modelContext.delete(photoItem)
        photos.removeAll { $0.id == photoItem.id }
        save()
    }

    func reorderPhotos(_ newOrder: [PhotoItem]) {
        for (index, photo) in newOrder.enumerated() {
            photo.sortOrder = index
        }
        photos = newOrder
        save()
    }

    private func loadPhotos() {
        let descriptor = FetchDescriptor<PhotoItem>(
            sortBy: [SortDescriptor(\.sortOrder)]
        )
        do {
            photos = try modelContext.fetch(descriptor)
        } catch {
            self.error = .fetchFailed(error)
        }
    }

    private func save() {
        do {
            try modelContext.save()
        } catch {
            self.error = .saveFailed(error)
        }
    }
}
```

### UserDefaults for App Groups (Widget Sync)

For widget support, use app groups:

```swift
@Observable
class AppGroupPhotoService {
    private let appGroupID = "group.com.yourapp"

    func savePhotoIdentifiers(_ identifiers: [String]) {
        if let defaults = UserDefaults(suiteName: appGroupID) {
            defaults.set(identifiers, forKey: "photoIdentifiers")
            defaults.synchronize()
        }
    }

    func loadPhotoIdentifiers() -> [String] {
        guard let defaults = UserDefaults(suiteName: appGroupID) else {
            return []
        }
        return defaults.stringArray(forKey: "photoIdentifiers") ?? []
    }
}
```

---

## 5. Common Patterns from Production Apps

### Instagram/Pinterest Pattern: Batch Import with Validation

```swift
struct BatchPhotoImporter {
    let photoLibrary = PhotoLibraryService.shared

    func importPhotosWithValidation(_ results: [PHPickerResult]) async -> ImportResult {
        var imported: [PhotoItem] = []
        var failed: [(PHPickerResult, Error)] = []

        // Phase 1: Extract identifiers and validate
        for result in results {
            guard let assetID = result.assetIdentifier else {
                failed.append((result, PhotoLoadError.invalidAsset))
                continue
            }

            // Validate photo exists and is accessible
            if photoLibrary.checkAssetExists(assetID) {
                imported.append(PhotoItem(
                    localIdentifier: assetID,
                    sortOrder: imported.count
                ))
            } else {
                failed.append((result, PhotoLoadError.assetNotFound))
            }
        }

        return ImportResult(
            imported: imported,
            failed: failed,
            successCount: imported.count
        )
    }
}
```

### Progressive Loading (Load Thumbnails First, Then HD)

```swift
class ProgressivePhotoLoader {
    static let shared = ProgressivePhotoLoader()
    private let manager = PHImageManager.default()

    func loadThumbnailThenHD(
        for identifier: String,
        onThumbnail: @escaping (UIImage?) -> Void,
        onFull: @escaping (UIImage?) -> Void
    ) {
        let fetchResult = PHAsset.fetchAssets(
            withLocalIdentifiers: [identifier],
            options: nil
        )
        guard let asset = fetchResult.firstObject else { return }

        // Load fast thumbnail
        let thumbOptions = PHImageRequestOptions()
        thumbOptions.deliveryMode = .fastFormat
        thumbOptions.isNetworkAccessAllowed = false

        manager.requestImage(
            for: asset,
            targetSize: CGSize(width: 100, height: 100),
            contentMode: .aspectFill,
            options: thumbOptions
        ) { image, _ in
            onThumbnail(image)
        }

        // Load high quality
        let hdOptions = PHImageRequestOptions()
        hdOptions.deliveryMode = .highQualityFormat
        hdOptions.isNetworkAccessAllowed = true
        hdOptions.progressHandler = { progress, _, _, _ in
            print("Loading: \(Int(progress * 100))%")
        }

        manager.requestImage(
            for: asset,
            targetSize: PHImageManagerMaximumSize,
            contentMode: .aspectFill,
            options: hdOptions
        ) { image, _ in
            onFull(image)
        }
    }
}
```

---

## 6. Error Handling & Edge Cases

### Comprehensive Error Types

```swift
enum PhotoLoadError: LocalizedError {
    case permissionDenied
    case assetNotFound
    case invalidAsset
    case loadingFailed(Error)
    case iCloudPhotoNotAvailable
    case memoryExceeded
    case unsupportedFormat
    case fetchFailed(Error)
    case saveFailed(Error)

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Photo library access denied"
        case .assetNotFound:
            return "Selected photo no longer exists"
        case .invalidAsset:
            return "Invalid photo selected"
        case .loadingFailed(let error):
            return "Failed to load photo: \(error.localizedDescription)"
        case .iCloudPhotoNotAvailable:
            return "iCloud photo unavailable. Check your internet connection."
        case .memoryExceeded:
            return "Not enough memory to load image"
        case .unsupportedFormat:
            return "This photo format is not supported"
        case .fetchFailed(let error):
            return "Failed to fetch photos: \(error.localizedDescription)"
        case .saveFailed(let error):
            return "Failed to save changes: \(error.localizedDescription)"
        }
    }
}
```

### Edge Case Handling

```swift
// 1. iCloud Photos (Requires Network)
func handleiCloudPhoto(_ result: PHPickerResult) async -> Result<UIImage, PhotoLoadError> {
    let itemProvider = result.itemProvider

    guard itemProvider.hasItemConformingToTypeIdentifier(UTType.image.identifier) else {
        return .failure(.invalidAsset)
    }

    return await withCheckedResult { continuation in
        itemProvider.loadObject(
            ofClass: UIImage.self
        ) { image, error in
            if let error = error as? NSError, error.code == -1 {
                // Limited photo access: asset not in allowed set
                continuation(.failure(.permissionDenied))
            } else if let image = image as? UIImage {
                continuation(.success(image))
            } else {
                continuation(.failure(.loadingFailed(error ?? NSError())))
            }
        }
    }
}

// 2. RAW Image Handling
func loadRAWImageIfAvailable(_ result: PHPickerResult) -> Result<URL, PhotoLoadError> {
    let itemProvider = result.itemProvider

    // Try loading RAW first
    if itemProvider.hasItemConformingToTypeIdentifier("com.adobe.raw-image") {
        // Handle RAW separately
        return .failure(.unsupportedFormat)
    }

    // Fall back to standard formats
    if itemProvider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
        // Load JPEG/PNG
        return .success(URL(fileURLWithPath: ""))
    }

    return .failure(.invalidAsset)
}

// 3. Limited Photo Access Check
func checkPhotoAvailability(_ assetIdentifier: String) -> Bool {
    let fetchResult = PHAsset.fetchAssets(
        withLocalIdentifiers: [assetIdentifier],
        options: nil
    )
    return fetchResult.count > 0
}
```

### Permission Handling

```swift
@Observable
class PhotoLibraryPermissionManager {
    var status: PHAuthorizationStatus = .notDetermined

    func requestAccess() async -> Bool {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)

        switch status {
        case .authorized, .limited:
            self.status = status
            return true
        case .notDetermined:
            let newStatus = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
            self.status = newStatus
            return newStatus == .authorized || newStatus == .limited
        case .denied, .restricted:
            self.status = status
            return false
        @unknown default:
            return false
        }
    }
}
```

---

## 7. Performance Optimization

### Memory-Efficient Image Loading

```swift
class MemoryEfficientImageLoader {
    static func loadImage(
        for identifier: String,
        targetSize: CGSize
    ) -> UIImage? {
        let fetchResult = PHAsset.fetchAssets(
            withLocalIdentifiers: [identifier],
            options: nil
        )
        guard let asset = fetchResult.firstObject else { return nil }

        // Critical: Use PHImageRequestOptions to control memory
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .fast
        options.isSynchronous = false  // Async is more efficient
        options.isNetworkAccessAllowed = true

        var resultImage: UIImage?

        PHImageManager.default().requestImage(
            for: asset,
            targetSize: targetSize,
            contentMode: .aspectFill,
            options: options
        ) { image, _ in
            resultImage = image
        }

        return resultImage
    }
}
```

### Thumbnail Downsampling (For Large Selections)

```swift
func createDownsampledThumbnail(
    from imageURL: URL,
    targetSize: CGSize
) -> UIImage? {
    let imageSourceOptions = [
        kCGImageSourceShouldCache: false
    ] as CFDictionary

    guard let imageSource = CGImageSourceCreateWithURL(
        imageURL as CFURL,
        imageSourceOptions
    ) else { return nil }

    let maxDimensionInPixels = max(targetSize.width, targetSize.height)
    let downsampleOptions = [
        kCGImageSourceCreateThumbnailFromImageAlways: true,
        kCGImageSourceShouldCacheImmediately: true,
        kCGImageSourceCreateThumbnailWithTransform: true,
        kCGImageSourceThumbnailMaxPixelSize: maxDimensionInPixels
    ] as CFDictionary

    guard let downsampledImage = CGImageSourceCreateThumbnailAtIndex(
        imageSource,
        0,
        downsampleOptions
    ) else { return nil }

    return UIImage(cgImage: downsampledImage)
}
```

### Image Caching Strategy

```swift
class PhotoImageCache {
    static let shared = PhotoImageCache()
    private let cache = NSCache<NSString, UIImage>()

    func cachedImage(for identifier: String) -> UIImage? {
        return cache.object(forKey: identifier as NSString)
    }

    func cache(_ image: UIImage, for identifier: String) {
        cache.setObject(image, forKey: identifier as NSString)
        // NSCache automatically purges under memory pressure
    }

    func clearCache() {
        cache.removeAllObjects()
    }
}
```

### Batch Loading with Concurrency

```swift
func loadPhotosBatch(
    identifiers: [String],
    batchSize: Int = 5
) async -> [UIImage?] {
    var images: [UIImage?] = []

    for batchStart in stride(from: 0, to: identifiers.count, by: batchSize) {
        let batchEnd = min(batchStart + batchSize, identifiers.count)
        let batch = identifiers[batchStart..<batchEnd]

        let batchImages = await withTaskGroup(
            of: UIImage?.self
        ) { group in
            for identifier in batch {
                group.addTask {
                    return MemoryEfficientImageLoader.loadImage(
                        for: identifier,
                        targetSize: CGSize(width: 200, height: 200)
                    )
                }
            }

            var results: [UIImage?] = []
            for await image in group {
                results.append(image)
            }
            return results
        }

        images.append(contentsOf: batchImages)
    }

    return images
}
```

### Optimization Checklist

- Use `deliveryMode: .fastFormat` for thumbnails, `.highQualityFormat` for display
- Always set `targetSize` appropriately (don't request full resolution for thumbnails)
- Use `resizeMode: .fast` for faster processing
- Enable `isNetworkAccessAllowed` only when necessary
- Cache thumbnails but not full resolution images
- Load images asynchronously, not synchronously
- Use `NSCache` which auto-purges under memory pressure
- Batch-load images to prevent memory spikes

---

## 8. Testing & Validation

### Mock Data for Previews

```swift
#Preview {
    @State var testViewModel = SlideshowViewModel()

    return PhotoManagementView(viewModel: testViewModel)
        .onAppear {
            // Add mock identifiers for preview
            testViewModel.photoIdentifiers = [
                "mock-id-1",
                "mock-id-2"
            ]
        }
}
```

### Unit Testing Error Cases

```swift
import XCTest

class PhotoLoaderTests: XCTestCase {
    func testMissingAssetDetection() {
        let invalidID = "invalid-asset-id"
        let exists = PhotoLibraryService.shared.checkAssetExists(invalidID)
        XCTAssertFalse(exists)
    }

    func testLimitedPhotoAccess() {
        // Test that out-of-scope photos are handled gracefully
        let testID = "limited-access-photo"
        let result = PhotoLibraryService.shared.checkAssetExists(testID)
        // Should return false, not crash
        XCTAssertFalse(result)
    }
}
```

---

## 9. Key Takeaways & Production Checklist

### Critical Production Requirements

- [ ] **Permissions**: Request photo library access with clear user explanation
- [ ] **Asset Validation**: Always validate that assets still exist before displaying
- [ ] **Error Handling**: Gracefully handle missing photos, iCloud unavailability, memory issues
- [ ] **Memory Management**: Use appropriate image sizes, enable caching, respect memory warnings
- [ ] **Data Persistence**: Store only asset identifiers, load images on-demand
- [ ] **Loading States**: Provide clear feedback during photo import and loading
- [ ] **Network Handling**: Check for iCloud photos and handle offline scenarios
- [ ] **Threading**: Ensure all UI updates happen on main thread
- [ ] **Accessibility**: Add accessibility labels to interactive elements
- [ ] **Testing**: Test with limited photo access, no access, iCloud photos, large selections

### Common Pitfalls to Avoid

1. **Storing full UIImage objects**: Store only asset identifiers
2. **Synchronous image loading**: Use async methods with proper callbacks
3. **Missing error handling**: Plan for missing photos and permission issues
4. **Unmanaged memory**: Control image sizes and use NSCache
5. **Blocking the main thread**: Load images asynchronously
6. **Ignoring iCloud status**: Handle network-dependent photo loading
7. **Wrong completion order**: Use proper async/await patterns, not assume order
8. **Memory leaks with closures**: Use `[weak self]` in capture lists

---

## References

### Official Apple Documentation
- [PHPickerViewController | Apple Developer Documentation](https://developer.apple.com/documentation/photosui/phpickerviewcontroller)
- [PHPickerConfiguration | Apple Developer Documentation](https://developer.apple.com/documentation/photosui/phpickerconfiguration-swift.struct)
- [PHPickerViewControllerDelegate | Apple Developer Documentation](https://developer.apple.com/documentation/photosui/phpickerviewcontrollerdelegate-5yntc)
- [Animating views and transitions — SwiftUI Tutorials](https://developer.apple.com/tutorials/swiftui/animating-views-and-transitions)

### Key Articles & Guides
- [Importing an image into SwiftUI using PHPickerViewController - Hacking with iOS](https://www.hackingwithswift.com/books/ios-swiftui/importing-an-image-into-swiftui-using-phpickerviewcontroller)
- [Using PHPickerViewController Images in a Memory-Efficient Way](https://christianselig.com/2020/09/phpickerviewcontroller-efficiently/)
- [The Complete Guide to PHPicker API in iOS 14](https://www.appcoda.com/phpicker/)
- [iOS Swift: PHPickerViewController Implementation - Real-life Insights](https://medium.com/@dari.tamim028/ios-swift-phpickerviewcontroller-implementation-real-life-insights-on-advantages-and-ab5f376185b9)
- [All about Item Providers](https://www.humancode.us/2023/07/08/all-about-nsitemprovider.html)
- [NSItemProvider | Apple Developer Documentation](https://developer.apple.com/documentation/foundation/nsitemprovider)

### Advanced Patterns
- [GitHub - AsyncItemProvider: A safe Swift Concurrency interface for NSItemProvider](https://github.com/harlanhaskins/AsyncItemProvider)
- [Material Design: Loading Images Patterns](https://m1.material.io/patterns/loading-images.html)

---

## Summary

Production-ready PHPickerViewController implementation requires attention to:

1. **Data Flow**: Store only asset identifiers; load images on-demand with proper caching
2. **UX**: Provide loading states, animations, and clear error messages
3. **Memory**: Use appropriate image sizes, respect memory warnings, cache efficiently
4. **Errors**: Handle missing photos, permission changes, network issues, and iCloud scenarios
5. **Threading**: Keep UI operations on the main thread, load asynchronously
6. **Testing**: Validate edge cases like limited access, offline, and missing assets

The implementation in the HerView app demonstrates a solid foundation using asset identifiers with SwiftData persistence and async image loading with proper state management.
