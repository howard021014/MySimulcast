struct ToggleFavouriteUseCase {
    private let repository: FavouritesRepositoryProtocol

    init(repository: FavouritesRepositoryProtocol) {
        self.repository = repository
    }

    /// Toggles the favourite state. Returns the new `isFavourited` value.
    func execute(animeID: Int, currentlyFavourited: Bool) async throws -> Bool {
        if currentlyFavourited {
            try await repository.removeFavourite(id: animeID)
            return false
        } else {
            try await repository.addFavourite(id: animeID)
            return true
        }
    }

    func loadFavouriteIDs() async throws -> Set<Int> {
        try await repository.favouriteIDs()
    }
}
