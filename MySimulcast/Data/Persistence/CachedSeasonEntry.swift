import SwiftData
import Foundation

@Model final class CachedSeasonEntry {
    var season: String
    var seasonYear: Int
    var animeID: Int
    var animeTitle: String
    var coverImageURLString: String?
    var thumbnailImageURLString: String?
    var descriptionText: String?
    var nextEpisode: Int?
    var nextAiringAt: Date?
    var animeSeason: String?
    var animeSeasonYear: Int?
    var fetchedAt: Date
    var sortOrder: Int = 0

    init(
        season: String,
        seasonYear: Int,
        animeID: Int,
        animeTitle: String,
        coverImageURLString: String?,
        thumbnailImageURLString: String?,
        descriptionText: String?,
        nextEpisode: Int?,
        nextAiringAt: Date?,
        animeSeason: String?,
        animeSeasonYear: Int?,
        fetchedAt: Date,
        sortOrder: Int
    ) {
        self.season = season
        self.seasonYear = seasonYear
        self.animeID = animeID
        self.animeTitle = animeTitle
        self.coverImageURLString = coverImageURLString
        self.thumbnailImageURLString = thumbnailImageURLString
        self.descriptionText = descriptionText
        self.nextEpisode = nextEpisode
        self.nextAiringAt = nextAiringAt
        self.animeSeason = animeSeason
        self.animeSeasonYear = animeSeasonYear
        self.fetchedAt = fetchedAt
        self.sortOrder = sortOrder
    }
}
