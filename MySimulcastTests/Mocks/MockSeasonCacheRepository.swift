import Foundation
@testable import MySimulcast

final class MockSeasonCacheRepository: SeasonCacheRepositoryProtocol, @unchecked Sendable {
    var cachedSeasons: [String: SimulcastSeason] = [:]

    private func key(season: Season, year: Int) -> String {
        "\(season.rawValue)-\(year)"
    }

    func loadCachedSeason(season: Season, year: Int) async -> SimulcastSeason? {
        cachedSeasons[key(season: season, year: year)]
    }

    func cacheSeason(_ simulcastSeason: SimulcastSeason) async {
        let k = key(season: simulcastSeason.season, year: simulcastSeason.year)
        cachedSeasons[k] = simulcastSeason
    }
}
