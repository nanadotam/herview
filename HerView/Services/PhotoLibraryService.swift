import Photos
import UIKit

@Observable
class PhotoLibraryService {
    static let shared = PhotoLibraryService()

    func requestPhotoLibraryAccess() async -> Bool {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        switch status {
        case .authorized, .limited:
            return true
        case .notDetermined:
            return await PHPhotoLibrary.requestAuthorization(for: .readWrite) == .authorized || PHPhotoLibrary.authorizationStatus(for: .readWrite) == .limited
        case .denied, .restricted:
            return false
        @unknown default:
            return false
        }
    }

    func loadImage(for localIdentifier: String, targetSize: CGSize) -> UIImage? {
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [localIdentifier], options: nil)
        guard let asset = fetchResult.firstObject else { return nil }

        let options = PHImageRequestOptions()
        options.isSynchronous = true
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .fast

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

    func checkAssetExists(localIdentifier: String) -> Bool {
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [localIdentifier], options: nil)
        return fetchResult.count > 0
    }
}
