import SwiftData
import Foundation

@ModelActor
actor SeasonCacheRepository: SeasonCacheRepositoryProtocol {

    func loadCachedSeason(season: Season, year: Int) async -> SimulcastSeason? {
        let seasonRaw = season.rawValue
        let predicate = #Predicate<CachedSeasonEntry> {
            $0.season == seasonRaw && $0.seasonYear == year
        }
        let descriptor = FetchDescriptor<CachedSeasonEntry>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.sortOrder)]
        )
        guard let entries = try? modelContext.fetch(descriptor), !entries.isEmpty else {
            return nil
        }
        let anime = entries.map { entry -> Anime in
            var airingSchedule: AiringSchedule?
            if let ep = entry.nextEpisode, let date = entry.nextAiringAt {
                airingSchedule = AiringSchedule(nextEpisode: ep, nextAiringAt: date)
            }
            return Anime(
                id: entry.animeID,
                title: entry.animeTitle,
                coverImageURL: entry.coverImageURLString.flatMap(URL.init(string:)),
                thumbnailImageURL: entry.thumbnailImageURLString.flatMap(URL.init(string:)),
                description: entry.descriptionText,
                airingSchedule: airingSchedule,
                season: entry.animeSeason.flatMap(Season.init(rawValue:)),
                seasonYear: entry.animeSeasonYear,
                isFavourited: false
            )
        }
        let fetchedAt = entries.map(\.fetchedAt).max() ?? Date()
        return SimulcastSeason(season: season, year: year, anime: anime, fetchedAt: fetchedAt)
    }

    func cacheSeason(_ simulcastSeason: SimulcastSeason) async {
        // Delete existing entries for this season/year
        let seasonRaw = simulcastSeason.season.rawValue
        let year = simulcastSeason.year
        let predicate = #Predicate<CachedSeasonEntry> {
            $0.season == seasonRaw && $0.seasonYear == year
        }
        let descriptor = FetchDescriptor<CachedSeasonEntry>(predicate: predicate)
        if let existing = try? modelContext.fetch(descriptor) {
            for entry in existing {
                modelContext.delete(entry)
            }
        }

        // Insert new entries
        for (index, anime) in simulcastSeason.anime.enumerated() {
            let entry = CachedSeasonEntry(
                season: seasonRaw,
                seasonYear: year,
                animeID: anime.id,
                animeTitle: anime.title,
                coverImageURLString: anime.coverImageURL?.absoluteString,
                thumbnailImageURLString: anime.thumbnailImageURL?.absoluteString,
                descriptionText: anime.description,
                nextEpisode: anime.airingSchedule?.nextEpisode,
                nextAiringAt: anime.airingSchedule?.nextAiringAt,
                animeSeason: anime.season?.rawValue,
                animeSeasonYear: anime.seasonYear,
                fetchedAt: simulcastSeason.fetchedAt,
                sortOrder: index
            )
            modelContext.insert(entry)
        }
        try? modelContext.save()
    }
}
