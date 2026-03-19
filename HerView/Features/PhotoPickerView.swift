import SwiftUI
import PhotosUI
import Photos

struct PhotoPickerView: View {
    @Environment(\.dismiss) var dismiss
    let viewModel: SlideshowViewModel

    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var selectedIdentifiers: [String] = []

    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.pink)
                    Spacer()
                    Text("Select Photos")
                        .font(.callout)
                        .fontWeight(.semibold)
                    Spacer()
                    Button("Add (\(selectedIdentifiers.count))") {
                        selectedIdentifiers.forEach { viewModel.addPhoto(with: $0) }
                        dismiss()
                    }
                    .foregroundColor(.pink)
                    .fontWeight(.semibold)
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 20)

                // Search bar placeholder
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    Text("Search")
                        .foregroundColor(.gray)
                    Spacer()
                }
                .padding(.horizontal, 12)
                .frame(height: 34)
                .background(Color(UIColor.systemGray5))
                .cornerRadius(10)
                .padding(.horizontal, 16)
                .padding(.bottom, 12)

                // Segmented control
                Picker("", selection: .constant(0)) {
                    Text("Recents").tag(0)
                    Text("Albums").tag(1)
                    Text("Favorites").tag(2)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.bottom, 16)

                // Photo grid
                ScrollView {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 3), spacing: 2) {
                        PhotoGridView(selectedIdentifiers: $selectedIdentifiers)
                    }
                    .padding(2)
                }
            }
            .background(Color(UIColor.systemGray6))
        }
        .onAppear {
            selectedIdentifiers = viewModel.photoIdentifiers
        }
    }
}

struct PhotoGridView: View {
    @Binding var selectedIdentifiers: [String]
    @State private var allPhotos: [PHAsset] = []

    var body: some View {
        Group {
            let photos = allPhotos.prefix(9)
            ForEach(photos, id: \.localIdentifier) { asset in
                ZStack(alignment: .topTrailing) {
                    PhotoThumbnail(asset: asset)

                    if selectedIdentifiers.contains(asset.localIdentifier) {
                        Circle()
                            .fill(Color.pink)
                            .frame(width: 22, height: 22)
                            .overlay(
                                Image(systemName: "checkmark")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                            )
                            .padding(6)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    if selectedIdentifiers.contains(asset.localIdentifier) {
                        selectedIdentifiers.removeAll { $0 == asset.localIdentifier }
                    } else {
                        selectedIdentifiers.append(asset.localIdentifier)
                    }
                }
            }
        }
        .onAppear {
            loadPhotos()
        }
    }

    private func loadPhotos() {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let results = PHAsset.fetchAssets(with: .image, options: fetchOptions)

        var photos: [PHAsset] = []
        results.enumerateObjects { asset, _, _ in
            photos.append(asset)
        }
        allPhotos = photos
    }
}

struct PhotoThumbnail: View {
    let asset: PHAsset
    @State private var image: UIImage?

    var body: some View {
        ZStack {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Color.gray.opacity(0.3)
            }
        }
        .aspectRatio(1, contentMode: .fill)
        .clipped()
        .onAppear {
            loadThumbnail()
        }
    }

    private func loadThumbnail() {
        let options = PHImageRequestOptions()
        options.deliveryMode = .fastFormat
        options.isSynchronous = true

        PHImageManager.default().requestImage(
            for: asset,
            targetSize: CGSize(width: 100, height: 100),
            contentMode: .aspectFill,
            options: options
        ) { image, _ in
            image.map { self.image = $0 }
        }
    }
}

#Preview {
    PhotoPickerView(viewModel: SlideshowViewModel())
}
