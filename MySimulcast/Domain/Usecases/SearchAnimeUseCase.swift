struct SearchAnimeUseCase {
    private let repository: AnimeRepositoryProtocol

    init(repository: AnimeRepositoryProtocol) {
        self.repository = repository
    }

    func execute(query: String, page: Int) async throws -> SearchResult {
        try await repository.searchAnime(query: query, page: page)
    }
}
