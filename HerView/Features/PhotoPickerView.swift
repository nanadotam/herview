import SwiftUI
import PhotosUI
import Photos

struct PhotoPickerView: View {
    @Environment(\.dismiss) var dismiss
    let viewModel: SlideshowViewModel

    var body: some View {
        ZStack {
            PHPickerRepresentable(viewModel: viewModel, isPresented: .constant(true)) { didAdd in
                if didAdd {
                    dismiss()
                }
            }
        }
    }
}

struct PHPickerRepresentable: UIViewControllerRepresentable {
    let viewModel: SlideshowViewModel
    @Binding var isPresented: Bool
    let onComplete: (Bool) -> Void

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.selectionLimit = 0  // Unlimited selection
        config.preferredAssetRepresentationMode = .current
        config.selection = .ordered

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel, onComplete: onComplete)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let viewModel: SlideshowViewModel
        let onComplete: (Bool) -> Void

        init(viewModel: SlideshowViewModel, onComplete: @escaping (Bool) -> Void) {
            self.viewModel = viewModel
            self.onComplete = onComplete
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            var addedCount = 0

            for result in results {
                result.itemProvider.loadFileRepresentation(forTypeIdentifier: "public.image") { url, error in
                    if let url = url {
                        // Get the PHAsset from the picker result
                        if let assetIdentifier = result.assetIdentifier {
                            self.viewModel.addPhoto(with: assetIdentifier)
                            addedCount += 1
                        }
                    }
                }
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.onComplete(addedCount > 0)
            }
        }
    }
}

#Preview {
    PhotoPickerView(viewModel: SlideshowViewModel())
}
