import Foundation

struct FetchSimulcastSeasonUseCase {
    private let repository: AnimeRepositoryProtocol
    private let cacheRepository: SeasonCacheRepositoryProtocol

    init(repository: AnimeRepositoryProtocol, cacheRepository: SeasonCacheRepositoryProtocol) {
        self.repository = repository
        self.cacheRepository = cacheRepository
    }

    func execute(season: Season, year: Int) async throws -> FetchSeasonResult {
        do {
            let result = try await repository.fetchSimulcastSeason(season: season, year: year)
            await cacheRepository.cacheSeason(result)
            return FetchSeasonResult(season: result, isFromCache: false)
        } catch {
            if let cached = await cacheRepository.loadCachedSeason(season: season, year: year) {
                return FetchSeasonResult(season: cached, isFromCache: true)
            }
            throw error
        }
    }
}
