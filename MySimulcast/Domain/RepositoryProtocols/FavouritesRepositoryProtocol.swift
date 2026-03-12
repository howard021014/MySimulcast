protocol FavouritesRepositoryProtocol {
    func favouriteIDs() async throws -> Set<Int>
    func addFavourite(anime: Anime, season: Season?, year: Int?, sortOrder: Int) async throws
    func removeFavourite(id: Int) async throws
    func allFavourites() async throws -> [FavouriteAnime]
}
