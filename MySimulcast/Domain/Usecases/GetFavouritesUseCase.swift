struct GetFavouritesUseCase {
    private let repository: FavouritesRepositoryProtocol

    init(repository: FavouritesRepositoryProtocol) {
        self.repository = repository
    }

    func execute() async throws -> [FavouriteAnime] {
        try await repository.allFavourites()
    }
}
