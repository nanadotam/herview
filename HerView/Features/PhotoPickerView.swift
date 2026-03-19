import SwiftUI
import PhotosUI
import Photos

struct PhotoPickerView: View {
    @Environment(\.dismiss) var dismiss
    let viewModel: SlideshowViewModel
    let onPhotosPicked: () -> Void
    @State private var isProcessing = false
    @State private var processingMessage = ""

    var body: some View {
        ZStack {
            PHPickerRepresentable(viewModel: viewModel, isPresented: .constant(true)) { results in
                handlePhotosPicked(results)
            }

            // Loading overlay
            if isProcessing {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text(processingMessage)
                        .font(.callout)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.3))
            }
        }
    }

    private func handlePhotosPicked(_ results: [PHPickerResult]) {
        print("📸 handlePhotosPicked called with \(results.count) results")
        isProcessing = true
        processingMessage = "Adding photos..."

        Task {
            var addedCount = 0
            let totalCount = results.count

            for (index, result) in results.enumerated() {
                await MainActor.run {
                    processingMessage = "Adding photo \(index + 1) of \(totalCount)..."
                }

                print("🔍 Processing result \(index + 1)")

                // Only add photos that have assetIdentifier (from library)
                if let assetIdentifier = result.assetIdentifier {
                    print("✅ Got assetIdentifier: \(assetIdentifier)")
                    let asset = PHAsset.fetchAssets(withLocalIdentifiers: [assetIdentifier], options: nil).firstObject

                    if asset != nil {
                        print("📝 Asset found, adding to viewModel")
                        viewModel.addPhoto(with: assetIdentifier)
                        addedCount += 1
                        print("✓ Added. Total: \(viewModel.photoIdentifiers.count)")
                    } else {
                        print("❌ Asset not found in library")
                    }
                } else {
                    print("⚠️ Photo doesn't have library identifier, skipping (not from camera roll)")
                }

                try? await Task.sleep(nanoseconds: 100_000_000)
            }

            // Show completion message
            if addedCount > 0 {
                await MainActor.run {
                    processingMessage = "Added \(addedCount) photo\(addedCount > 1 ? "s" : "")!"
                }
                try? await Task.sleep(nanoseconds: 500_000_000)
                await MainActor.run {
                    onPhotosPicked()
                    dismiss()
                }
            } else {
                await MainActor.run {
                    processingMessage = "No photos added"
                }
                try? await Task.sleep(nanoseconds: 500_000_000)
                await MainActor.run {
                    isProcessing = false
                }
            }
        }
    }
}

struct PHPickerRepresentable: UIViewControllerRepresentable {
    let viewModel: SlideshowViewModel
    @Binding var isPresented: Bool
    let onComplete: ([PHPickerResult]) -> Void

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.selectionLimit = 0
        config.preferredAssetRepresentationMode = .current
        config.selection = .ordered
        config.filter = .images

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
            print("🎬 picker didFinishPicking called with \(results.count) results")
            picker.dismiss(animated: true) {
                print("✨ Calling onComplete with \(results.count) results")
                self.onComplete(results)
            }
        }
    }
}

// #Preview {
//    PhotoPickerView(viewModel: SlideshowViewModel(), onPhotosPicked: {})
// }
