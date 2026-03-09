import Foundation

protocol SeasonCacheRepositoryProtocol: Sendable {
    func loadCachedSeason(season: Season, year: Int) async -> SimulcastSeason?
    func cacheSeason(_ simulcastSeason: SimulcastSeason) async
}
