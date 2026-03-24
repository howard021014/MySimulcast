import Testing
import Foundation
@testable import MySimulcast

final class MockFavouritesRepository: FavouritesRepositoryProtocol {
    var ids: Set<Int> = []
    var storedFavourites: [FavouriteAnime] = []

    func favouriteIDs() async throws -> Set<Int> { ids }

    func addFavourite(anime: Anime, season: Season?, year: Int?, sortOrder: Int) async throws {
        ids.insert(anime.id)
        storedFavourites.append(FavouriteAnime(anime: anime, season: season, year: year, addedAt: Date(), sortOrder: sortOrder))
    }

    func removeFavourite(id: Int) async throws {
        ids.remove(id)
        storedFavourites.removeAll { $0.anime.id == id }
    }

    func allFavourites() async throws -> [FavouriteAnime] { storedFavourites }
}

private let testAnime = Anime(
    id: 1, title: "Test Anime", coverImageURL: nil, thumbnailImageURL: nil,
    description: nil, airingSchedule: nil, season: nil, seasonYear: nil, isFavourited: false
)

@Suite("ToggleFavouriteUseCase")
struct ToggleFavouriteUseCaseTests {

    @Test("Adding a favourite inserts ID and returns true")
    func addFavourite() async throws {
        let repo = MockFavouritesRepository()
        let useCase = ToggleFavouriteUseCase(repository: repo)

        let result = try await useCase.execute(anime: testAnime, season: .winter, year: 2026, sortOrder: 0, currentlyFavourited: false)

        #expect(result == true)
        #expect(repo.ids.contains(1))
    }

    @Test("Removing a favourite deletes ID and returns false")
    func removeFavourite() async throws {
        let repo = MockFavouritesRepository()
        repo.ids = [1]
        let useCase = ToggleFavouriteUseCase(repository: repo)

        let result = try await useCase.execute(anime: testAnime, season: .winter, year: 2026, sortOrder: 0, currentlyFavourited: true)

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
        let notificationService = MockNotificationService()
        let scheduleUseCase = ScheduleNotificationUseCase(notificationService: notificationService, isNotificationsEnabled: { true })
        let manageUseCase = ManageNotificationsUseCase(scheduleUseCase: scheduleUseCase, favouritesRepository: favouritesRepo, notificationService: notificationService)
        let toggleUseCase = ToggleFavouriteUseCase(repository: favouritesRepo)
        let favouriteManager = FavouriteManager(
            toggleUseCase: toggleUseCase,
            scheduleNotificationUseCase: scheduleUseCase,
            imageCache: ImageCache()
        )
        let cache = MockSeasonCacheRepository()
        return SimulcastBrowseViewModel(
            useCase: FetchSimulcastSeasonUseCase(repository: animeRepo, cacheRepository: cache),
            manageNotificationsUseCase: manageUseCase,
            networkStatus: MockNetworkStatus(),
            favouriteManager: favouriteManager
        )
    }

    @Test("Anime reflects loaded favourite IDs")
    func animeReflectsFavouriteIDs() async {
        let anime = [
            Anime(id: 1, title: "A", coverImageURL: nil, thumbnailImageURL: nil,
                  description: nil, airingSchedule: nil, season: nil, seasonYear: nil, isFavourited: false),
            Anime(id: 2, title: "B", coverImageURL: nil, thumbnailImageURL: nil,
                  description: nil, airingSchedule: nil, season: nil, seasonYear: nil, isFavourited: false)
        ]
        let viewModel = makeViewModel(anime: anime, favouriteIDs: [2])

        let target = viewModel.selectedSeason
        await viewModel.loadSeason(target)

        let loaded = viewModel.anime(for: target)
        #expect(loaded.first(where: { $0.id == 1 })?.isFavourited == false)
        #expect(loaded.first(where: { $0.id == 2 })?.isFavourited == true)
    }

    @Test("Toggle favourite adds to favourites")
    func toggleAdds() async {
        let anime = Anime(id: 1, title: "A", coverImageURL: nil, thumbnailImageURL: nil,
                          description: nil, airingSchedule: nil, season: nil, seasonYear: nil, isFavourited: false)
        let viewModel = makeViewModel(anime: [anime])

        let target = viewModel.selectedSeason
        await viewModel.loadSeason(target)
        await viewModel.toggleFavourite(anime: anime)

        #expect(viewModel.anime(for: target).first?.isFavourited == true)
    }

    @Test("Toggle favourite removes from favourites")
    func toggleRemoves() async {
        let anime = Anime(id: 1, title: "A", coverImageURL: nil, thumbnailImageURL: nil,
                          description: nil, airingSchedule: nil, season: nil, seasonYear: nil, isFavourited: false)
        let viewModel = makeViewModel(anime: [anime], favouriteIDs: [1])

        let target = viewModel.selectedSeason
        await viewModel.loadSeason(target)
        await viewModel.toggleFavourite(anime: anime)

        #expect(viewModel.anime(for: target).first?.isFavourited == false)
    }
}
