import SwiftData
import Foundation

@ModelActor
actor FavouritesRepository: FavouritesRepositoryProtocol {
    func favouriteIDs() async throws -> Set<Int> {
        let entries = try modelContext.fetch(FetchDescriptor<FavouriteEntry>())
        return Set(entries.map(\.animeID))
    }

    func addFavourite(anime: Anime, season: Season?, year: Int?, sortOrder: Int) async throws {
        modelContext.insert(FavouriteEntry(anime: anime, season: season, year: year, sortOrder: sortOrder))
        try modelContext.save()
    }

    func removeFavourite(id: Int) async throws {
        let entries = try modelContext.fetch(FetchDescriptor<FavouriteEntry>())
        if let entry = entries.first(where: { $0.animeID == id }) {
            modelContext.delete(entry)
            try modelContext.save()
        }
    }

    func allFavourites() async throws -> [FavouriteAnime] {
        var descriptor = FetchDescriptor<FavouriteEntry>(
            sortBy: [SortDescriptor(\.sortOrder, order: .forward)]
        )
        descriptor.fetchLimit = 500
        let entries = try modelContext.fetch(descriptor)
        return entries.map { entry in
            let season: Season? = entry.season.flatMap { Season(rawValue: $0) }
            var airingSchedule: AiringSchedule?
            if let ep = entry.nextEpisode, let date = entry.nextAiringAt {
                airingSchedule = AiringSchedule(nextEpisode: ep, nextAiringAt: date)
            }
            let anime = Anime(
                id: entry.animeID,
                title: entry.animeTitle,
                coverImageURL: entry.coverImageURLString.flatMap(URL.init(string:)),
                thumbnailImageURL: entry.thumbnailImageURLString.flatMap(URL.init(string:)),
                description: entry.synopsis,
                airingSchedule: airingSchedule,
                season: season,
                seasonYear: entry.seasonYear,
                isFavourited: true,
                studios: entry.studios,
                genres: entry.genres,
                episodes: entry.episodes
            )
            return FavouriteAnime(anime: anime, season: season, year: entry.seasonYear, addedAt: entry.addedAt, sortOrder: entry.sortOrder)
        }
    }
}
