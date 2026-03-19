import SwiftData
import Foundation

@Model
final class PhotoItem {
    var id: UUID
    var localIdentifier: String
    var sortOrder: Int
    var dateAdded: Date

    init(localIdentifier: String, sortOrder: Int) {
        self.id = UUID()
        self.localIdentifier = localIdentifier
        self.sortOrder = sortOrder
        self.dateAdded = .now
    }
}
