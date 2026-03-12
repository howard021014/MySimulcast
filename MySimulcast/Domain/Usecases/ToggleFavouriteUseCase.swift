struct ToggleFavouriteUseCase {
    private let repository: FavouritesRepositoryProtocol

    init(repository: FavouritesRepositoryProtocol) {
        self.repository = repository
    }

    /// Toggles the favourite state. Returns the new `isFavourited` value.
    func execute(anime: Anime, season: Season?, year: Int?, sortOrder: Int, currentlyFavourited: Bool) async throws -> Bool {
        if currentlyFavourited {
            try await repository.removeFavourite(id: anime.id)
            return false
        } else {
            try await repository.addFavourite(anime: anime, season: season, year: year, sortOrder: sortOrder)
            return true
        }
    }

    func loadFavouriteIDs() async throws -> Set<Int> {
        try await repository.favouriteIDs()
    }
}
