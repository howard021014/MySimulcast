protocol AnimeRepositoryProtocol {
    func fetchSimulcastSeason(season: Season, year: Int) async throws -> SimulcastSeason
    func searchAnime(query: String, page: Int) async throws -> SearchResult
}
