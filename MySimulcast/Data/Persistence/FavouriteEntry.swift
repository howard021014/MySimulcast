import SwiftData
import Foundation

@Model final class FavouriteEntry {
    var animeID: Int
    var animeTitle: String
    var coverImageURLString: String?
    var thumbnailImageURLString: String?
    var season: String?
    var seasonYear: Int?
    var addedAt: Date
    var nextEpisode: Int?
    var nextAiringAt: Date?
    var sortOrder: Int = Int.max
    var synopsis: String?
    var studios: [String]?
    var genres: [String]?
    var episodes: Int?

    init(anime: Anime, season: Season?, year: Int?, sortOrder: Int) {
        self.animeID = anime.id
        self.animeTitle = anime.title
        self.coverImageURLString = anime.coverImageURL?.absoluteString
        self.thumbnailImageURLString = anime.thumbnailImageURL?.absoluteString
        self.season = season?.rawValue
        self.seasonYear = year
        self.addedAt = Date()
        self.nextEpisode = anime.airingSchedule?.nextEpisode
        self.nextAiringAt = anime.airingSchedule?.nextAiringAt
        self.sortOrder = sortOrder
        self.synopsis = anime.description
        self.studios = anime.studios
        self.genres = anime.genres
        self.episodes = anime.episodes
    }
}
