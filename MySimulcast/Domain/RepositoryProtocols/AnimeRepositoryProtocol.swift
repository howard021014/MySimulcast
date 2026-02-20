protocol AnimeRepositoryProtocol {
    func fetchSimulcastSeason(season: Season, year: Int) async throws -> SimulcastSeason
}
