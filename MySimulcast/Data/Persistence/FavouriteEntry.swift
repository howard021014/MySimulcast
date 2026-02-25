import SwiftData
import Foundation

@Model final class FavouriteEntry {
    var animeID: Int
    var animeTitle: String
    var coverImageURLString: String?
    var thumbnailImageURLString: String?
    var season: String
    var seasonYear: Int
    var addedAt: Date
    var nextEpisode: Int?
    var nextAiringAt: Date?

    init(anime: Anime, season: Season, year: Int) {
        self.animeID = anime.id
        self.animeTitle = anime.title
        self.coverImageURLString = anime.coverImageURL?.absoluteString
        self.thumbnailImageURLString = anime.thumbnailImageURL?.absoluteString
        self.season = season.rawValue
        self.seasonYear = year
        self.addedAt = Date()
        self.nextEpisode = anime.airingSchedule?.nextEpisode
        self.nextAiringAt = anime.airingSchedule?.nextAiringAt
    }
}
