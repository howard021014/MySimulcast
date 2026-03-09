import Testing
import Foundation
@testable import MySimulcast

@Suite("MockSeasonCacheRepository")
struct SeasonCacheRepositoryTests {

    @Test("Round-trip cache and load")
    func roundTrip() async {
        let repo = MockSeasonCacheRepository()
        let anime = Anime(id: 1, title: "Test", coverImageURL: nil, thumbnailImageURL: nil,
                          description: "desc", airingSchedule: AiringSchedule(nextEpisode: 3, nextAiringAt: Date()),
                          season: .winter, seasonYear: 2026, isFavourited: false)
        let season = SimulcastSeason(season: .winter, year: 2026, anime: [anime], fetchedAt: Date())

        await repo.cacheSeason(season)
        let loaded = await repo.loadCachedSeason(season: .winter, year: 2026)

        #expect(loaded != nil)
        #expect(loaded?.anime.count == 1)
        #expect(loaded?.anime.first?.title == "Test")
    }

    @Test("Returns nil on cache miss")
    func cacheMiss() async {
        let repo = MockSeasonCacheRepository()
        let result = await repo.loadCachedSeason(season: .summer, year: 2025)
        #expect(result == nil)
    }
}
