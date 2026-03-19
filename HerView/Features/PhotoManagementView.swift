import SwiftUI
import Photos

struct PhotoManagementView: View {
    let viewModel: SlideshowViewModel
    @State private var showingPhotoPicker = false
    @State private var photoLibraryStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)

    var body: some View {
        NavigationStack {
            VStack {
                // Header
                HStack {
                    Text("My Photos")
                        .font(.system(size: 28, weight: .bold))
                    Spacer()
                    Button(action: { showingPhotoPicker = true }) {
                        HStack(spacing: 5) {
                            Text("+")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Add")
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 14)
                        .background(Color.pink)
                        .foregroundColor(.white)
                        .cornerRadius(20)
                        .font(.system(size: 14, weight: .semibold))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)

                // Count bar
                HStack(spacing: 8) {
                    Text("\(viewModel.photoIdentifiers.count) photos · shuffling")
                        .font(.callout)
                        .foregroundColor(.gray)
                    Circle()
                        .fill(Color.green)
                        .frame(width: 6, height: 6)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)

                // Photo list
                if viewModel.photoIdentifiers.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "photo.badge.plus")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        Text("No photos yet")
                            .font(.callout)
                            .fontWeight(.semibold)
                        Text("Tap Add to select photos from your library")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(UIColor.systemGray6))
                } else {
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(Array(viewModel.photoIdentifiers.enumerated()), id: \.element) { index, identifier in
                                PhotoManagementRow(
                                    identifier: identifier,
                                    isCurrentPhoto: viewModel.currentPhotoIdentifier == identifier,
                                    index: index + 1,
                                    onDelete: { viewModel.removePhoto(with: identifier) }
                                )
                            }
                        }
                        .background(Color.white)
                        .cornerRadius(12)
                        .padding(.horizontal, 16)
                    }

                    Text("Swipe left to remove · Drag = to reorder")
                        .font(.caption2)
                        .foregroundColor(.gray)
                        .padding(.vertical, 12)
                }

                Spacer()
            }
            .background(Color(UIColor.systemGray6))
            .sheet(isPresented: $showingPhotoPicker) {
                PhotoPickerView(viewModel: viewModel)
            }
            .navigationTitle("Photos")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await requestPhotoAccess()
            }
        }
    }

    private func requestPhotoAccess() async {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        if status == .notDetermined {
            let newStatus = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
            await MainActor.run {
                photoLibraryStatus = newStatus
            }
        }
    }
}

struct PhotoManagementRow: View {
    let identifier: String
    let isCurrentPhoto: Bool
    let index: Int
    let onDelete: () -> Void
    @State private var image: UIImage?

    var body: some View {
        HStack(spacing: 12) {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 52, height: 52)
                    .cornerRadius(10)
            } else {
                Color.gray.opacity(0.3)
                    .frame(width: 52, height: 52)
                    .cornerRadius(10)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Photo \(index)")
                    .font(.callout)
                    .fontWeight(.semibold)
                Text("Added today")
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Spacer()

            if isCurrentPhoto {
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.pink)
                        .frame(width: 6, height: 6)
                    Text("Current")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.pink)
                }
            } else {
                Text("=")
                    .font(.system(size: 18))
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .background(Color.white)
        .contentShape(Rectangle())
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .onAppear {
            loadThumbnail()
        }
    }

    private func loadThumbnail() {
        let options = PHImageRequestOptions()
        options.deliveryMode = .fastFormat
        options.isSynchronous = false

        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil)
        guard let asset = fetchResult.firstObject else {
            return
        }

        PHImageManager.default().requestImage(
            for: asset,
            targetSize: CGSize(width: 52, height: 52),
            contentMode: .aspectFill,
            options: options
        ) { image, _ in
            if let image = image {
                DispatchQueue.main.async {
                    self.image = image
                }
            }
        }
    }
}

#Preview {
    PhotoManagementView(viewModel: SlideshowViewModel())
}
