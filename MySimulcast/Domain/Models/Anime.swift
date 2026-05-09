import Foundation

struct Anime: Identifiable, Codable {
    let id: Int
    let title: String
    let coverImageURL: URL?
    let thumbnailImageURL: URL?
    let description: String?
    let airingSchedule: AiringSchedule?
    let season: Season?
    let seasonYear: Int?
    var isFavourited: Bool
    let studios: [String]?
    let genres: [String]?
    let episodes: Int?

    init(
        id: Int,
        title: String,
        coverImageURL: URL?,
        thumbnailImageURL: URL?,
        description: String?,
        airingSchedule: AiringSchedule?,
        season: Season?,
        seasonYear: Int?,
        isFavourited: Bool,
        studios: [String]? = nil,
        genres: [String]? = nil,
        episodes: Int? = nil
    ) {
        self.id = id
        self.title = title
        self.coverImageURL = coverImageURL
        self.thumbnailImageURL = thumbnailImageURL
        self.description = description
        self.airingSchedule = airingSchedule
        self.season = season
        self.seasonYear = seasonYear
        self.isFavourited = isFavourited
        self.studios = studios
        self.genres = genres
        self.episodes = episodes
    }
}
