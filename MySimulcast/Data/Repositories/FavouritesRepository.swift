import SwiftData

@ModelActor
actor FavouritesRepository: FavouritesRepositoryProtocol {
    func favouriteIDs() async throws -> Set<Int> {
        let entries = try modelContext.fetch(FetchDescriptor<FavouriteEntry>())
        return Set(entries.map(\.animeID))
    }

    func addFavourite(id: Int) async throws {
        modelContext.insert(FavouriteEntry(animeID: id))
        try modelContext.save()
    }

    func removeFavourite(id: Int) async throws {
        let entries = try modelContext.fetch(FetchDescriptor<FavouriteEntry>())
        if let entry = entries.first(where: { $0.animeID == id }) {
            modelContext.delete(entry)
            try modelContext.save()
        }
    }
}
