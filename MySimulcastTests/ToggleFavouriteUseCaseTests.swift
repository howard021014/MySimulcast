import Testing
import Foundation
@testable import MySimulcast

final class MockFavouritesRepository: FavouritesRepositoryProtocol {
    var ids: Set<Int> = []

    func favouriteIDs() async throws -> Set<Int> { ids }
    func addFavourite(id: Int) async throws { ids.insert(id) }
    func removeFavourite(id: Int) async throws { ids.remove(id) }
}

@Suite("ToggleFavouriteUseCase")
struct ToggleFavouriteUseCaseTests {

    @Test("Adding a favourite inserts ID and returns true")
    func addFavourite() async throws {
        let repo = MockFavouritesRepository()
        let useCase = ToggleFavouriteUseCase(repository: repo)

        let result = try await useCase.execute(animeID: 1, currentlyFavourited: false)

        #expect(result == true)
        #expect(repo.ids.contains(1))
    }

    @Test("Removing a favourite deletes ID and returns false")
    func removeFavourite() async throws {
        let repo = MockFavouritesRepository()
        repo.ids = [1]
        let useCase = ToggleFavouriteUseCase(repository: repo)

        let result = try await useCase.execute(animeID: 1, currentlyFavourited: true)

        #expect(result == false)
        #expect(!repo.ids.contains(1))
    }

    @Test("loadFavouriteIDs delegates to repository")
    func loadFavouriteIDs() async throws {
        let repo = MockFavouritesRepository()
        repo.ids = [1, 2, 3]
        let useCase = ToggleFavouriteUseCase(repository: repo)

        let ids = try await useCase.loadFavouriteIDs()

        #expect(ids == [1, 2, 3])
    }
}

@Suite("SimulcastBrowseViewModel — favourites")
struct SimulcastBrowseViewModelFavouritesTests {

    private func makeViewModel(
        anime: [Anime] = [],
        favouriteIDs: Set<Int> = []
    ) -> SimulcastBrowseViewModel {
        let animeRepo = MockAnimeRepository()
        animeRepo.result = .success(
            SimulcastSeason(season: .winter, year: 2026, anime: anime, fetchedAt: Date())
        )
        let favouritesRepo = MockFavouritesRepository()
        favouritesRepo.ids = favouriteIDs
        return SimulcastBrowseViewModel(
            useCase: FetchSimulcastSeasonUseCase(repository: animeRepo),
            toggleUseCase: ToggleFavouriteUseCase(repository: favouritesRepo)
        )
    }

    @Test("Anime reflects loaded favourite IDs")
    func animeReflectsFavouriteIDs() async {
        let anime = [
            Anime(id: 1, title: "A", coverImageURL: nil, thumbnailImageURL: nil,
                  description: nil, airingSchedule: nil, isFavourited: false),
            Anime(id: 2, title: "B", coverImageURL: nil, thumbnailImageURL: nil,
                  description: nil, airingSchedule: nil, isFavourited: false)
        ]
        let viewModel = makeViewModel(anime: anime, favouriteIDs: [2])

        await viewModel.loadSeason()

        let loaded = viewModel.anime
        #expect(loaded.first(where: { $0.id == 1 })?.isFavourited == false)
        #expect(loaded.first(where: { $0.id == 2 })?.isFavourited == true)
    }

    @Test("Toggle favourite adds to favourites")
    func toggleAdds() async {
        let anime = Anime(id: 1, title: "A", coverImageURL: nil, thumbnailImageURL: nil,
                          description: nil, airingSchedule: nil, isFavourited: false)
        let viewModel = makeViewModel(anime: [anime])

        await viewModel.loadSeason()
        await viewModel.toggleFavourite(anime: anime)

        #expect(viewModel.anime.first?.isFavourited == true)
    }

    @Test("Toggle favourite removes from favourites")
    func toggleRemoves() async {
        let anime = Anime(id: 1, title: "A", coverImageURL: nil, thumbnailImageURL: nil,
                          description: nil, airingSchedule: nil, isFavourited: false)
        let viewModel = makeViewModel(anime: [anime], favouriteIDs: [1])

        await viewModel.loadSeason()
        await viewModel.toggleFavourite(anime: anime)

        #expect(viewModel.anime.first?.isFavourited == false)
    }
}
