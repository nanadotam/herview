import SwiftUI
import WidgetKit
import Photos

struct HerViewWidgetView: View {
    let entry: HerViewEntry

    @ViewBuilder
    var body: some View {
        if let identifier = entry.photoIdentifier {
            ZStack {
                // Load and display the photo
                PhotoWidgetContent(identifier: identifier)
            }
            .containerRelativeFrame([.horizontal, .vertical])
        } else {
            // Empty state
            ZStack {
                Color(UIColor.systemGray6)
                VStack(spacing: 8) {
                    Image(systemName: "photo")
                        .font(.system(size: 24))
                        .foregroundColor(.gray)
                    Text("Open HerView")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .containerRelativeFrame([.horizontal, .vertical])
        }
    }
}

struct PhotoWidgetContent: View {
    let identifier: String
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
        .onAppear {
            loadPhoto()
        }
    }

    private func loadPhoto() {
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil)
        guard let asset = fetchResult.firstObject else { return }

        let options = PHImageRequestOptions()
        options.isSynchronous = true
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .fast

        PHImageManager.default().requestImage(
            for: asset,
            targetSize: CGSize(width: 400, height: 400),
            contentMode: .aspectFill,
            options: options
        ) { image, _ in
            image.map { self.image = $0 }
        }
    }
}

#Preview(as: .systemSmall) {
    HerViewWidgetView(entry: HerViewEntry(date: Date(), photoIdentifier: nil))
} timeline: {
    HerViewEntry(date: Date(), photoIdentifier: nil)
}
