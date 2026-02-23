import SwiftData
import Foundation

@Model final class FavouriteEntry {
    var animeID: Int
    var addedAt: Date

    init(animeID: Int) {
        self.animeID = animeID
        self.addedAt = Date()
    }
}
