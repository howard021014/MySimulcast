protocol FavouritesRepositoryProtocol {
    func favouriteIDs() async throws -> Set<Int>
    func addFavourite(id: Int) async throws
    func removeFavourite(id: Int) async throws
}
