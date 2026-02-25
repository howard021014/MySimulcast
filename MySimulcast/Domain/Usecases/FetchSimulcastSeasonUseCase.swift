import Foundation

struct FetchSimulcastSeasonUseCase {
    private let repository: AnimeRepositoryProtocol

    init(repository: AnimeRepositoryProtocol) {
        self.repository = repository
    }

    func execute(season: Season, year: Int) async throws -> SimulcastSeason {
        try await repository.fetchSimulcastSeason(season: season, year: year)
    }
}
