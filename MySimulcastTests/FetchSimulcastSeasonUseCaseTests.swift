import Testing
import Foundation
@testable import MySimulcast

final class MockAnimeRepository: AnimeRepositoryProtocol {
    var result: Result<SimulcastSeason, Error> = .success(
        SimulcastSeason(season: .winter, year: 2026, anime: [], fetchedAt: Date())
    )

    func fetchSimulcastSeason(season: Season, year: Int) async throws -> SimulcastSeason {
        try result.get()
    }

    var searchResult: Result<SearchResult, Error> = .success(
        SearchResult(anime: [], currentPage: 1, hasNextPage: false)
    )

    func searchAnime(query: String, page: Int) async throws -> SearchResult {
        try searchResult.get()
    }
}

@Suite("FetchSimulcastSeasonUseCase")
struct FetchSimulcastSeasonUseCaseTests {

    @Test("Returns season from repository")
    func returnsSeasonFromRepository() async throws {
        let expected = SimulcastSeason(season: .winter, year: 2026, anime: [], fetchedAt: Date())
        let repo = MockAnimeRepository()
        repo.result = .success(expected)
        let cache = MockSeasonCacheRepository()
        let useCase = FetchSimulcastSeasonUseCase(repository: repo, cacheRepository: cache)

        let result = try await useCase.execute(season: .winter, year: 2026)

        #expect(result.season.season == expected.season)
        #expect(result.season.year == expected.year)
        #expect(result.isFromCache == false)
    }

    @Test("Network success caches the result")
    func networkSuccessCaches() async throws {
        let expected = SimulcastSeason(season: .winter, year: 2026, anime: [], fetchedAt: Date())
        let repo = MockAnimeRepository()
        repo.result = .success(expected)
        let cache = MockSeasonCacheRepository()
        let useCase = FetchSimulcastSeasonUseCase(repository: repo, cacheRepository: cache)

        _ = try await useCase.execute(season: .winter, year: 2026)

        let cached = await cache.loadCachedSeason(season: .winter, year: 2026)
        #expect(cached != nil)
    }

    @Test("Network failure returns cached data")
    func networkFailureReturnsCache() async throws {
        struct TestError: Error {}
        let repo = MockAnimeRepository()
        repo.result = .failure(TestError())
        let cache = MockSeasonCacheRepository()
        let cachedSeason = SimulcastSeason(season: .winter, year: 2026, anime: [], fetchedAt: Date())
        await cache.cacheSeason(cachedSeason)
        let useCase = FetchSimulcastSeasonUseCase(repository: repo, cacheRepository: cache)

        let result = try await useCase.execute(season: .winter, year: 2026)

        #expect(result.isFromCache == true)
        #expect(result.season.season == .winter)
    }

    @Test("Network failure with no cache rethrows error")
    func networkFailureNoCacheThrows() async {
        struct TestError: Error {}
        let repo = MockAnimeRepository()
        repo.result = .failure(TestError())
        let cache = MockSeasonCacheRepository()
        let useCase = FetchSimulcastSeasonUseCase(repository: repo, cacheRepository: cache)

        await #expect(throws: TestError.self) {
            try await useCase.execute(season: .winter, year: 2026)
        }
    }

    @Test("Jan–Mar is winter", arguments: [1, 2, 3])
    func winterMonths(month: Int) {
        let date = Calendar.current.date(from: DateComponents(year: 2026, month: month))!
        let (season, _) = Season.current(for: date)
        #expect(season == .winter)
    }

    @Test("Apr–Jun is spring", arguments: [4, 5, 6])
    func springMonths(month: Int) {
        let date = Calendar.current.date(from: DateComponents(year: 2026, month: month))!
        let (season, _) = Season.current(for: date)
        #expect(season == .spring)
    }

    @Test("Jul–Sep is summer", arguments: [7, 8, 9])
    func summerMonths(month: Int) {
        let date = Calendar.current.date(from: DateComponents(year: 2026, month: month))!
        let (season, _) = Season.current(for: date)
        #expect(season == .summer)
    }

    @Test("Oct–Dec is fall", arguments: [10, 11, 12])
    func fallMonths(month: Int) {
        let date = Calendar.current.date(from: DateComponents(year: 2026, month: month))!
        let (season, _) = Season.current(for: date)
        #expect(season == .fall)
    }
}

@Suite("SimulcastBrowseViewModel — legacy")
struct SimulcastBrowseViewModelLegacyTests {

    private func makeViewModel(useCase: FetchSimulcastSeasonUseCase, toggleUseCase: ToggleFavouriteUseCase, networkStatus: MockNetworkStatus = MockNetworkStatus()) -> SimulcastBrowseViewModel {
        let service = MockNotificationService()
        let repo = MockFavouritesRepository()
        let scheduleUseCase = ScheduleNotificationUseCase(notificationService: service, isNotificationsEnabled: { true })
        let manageUseCase = ManageNotificationsUseCase(scheduleUseCase: scheduleUseCase, favouritesRepository: repo, notificationService: service)
        return SimulcastBrowseViewModel(useCase: useCase, toggleUseCase: toggleUseCase, scheduleNotificationUseCase: scheduleUseCase, manageNotificationsUseCase: manageUseCase, networkStatus: networkStatus)
    }

    @Test("Starts with all seasons idle")
    func startsIdle() {
        let repo = MockAnimeRepository()
        let cache = MockSeasonCacheRepository()
        let useCase = FetchSimulcastSeasonUseCase(repository: repo, cacheRepository: cache)
        let toggleUseCase = ToggleFavouriteUseCase(repository: MockFavouritesRepository())
        let viewModel = makeViewModel(useCase: useCase, toggleUseCase: toggleUseCase)

        let state = viewModel.stateForSeason(viewModel.selectedSeason)
        if case .idle = state { } else {
            Issue.record("Expected idle state")
        }
    }

    @Test("Transitions to loaded")
    func transitionsToLoaded() async {
        let anime = [Anime(id: 1, title: "Test", coverImageURL: nil, thumbnailImageURL: nil,
                           description: nil, airingSchedule: nil, season: nil, seasonYear: nil, isFavourited: false)]
        let season = SimulcastSeason(season: .winter, year: 2026, anime: anime, fetchedAt: Date())
        let repo = MockAnimeRepository()
        repo.result = .success(season)
        let cache = MockSeasonCacheRepository()
        let useCase = FetchSimulcastSeasonUseCase(repository: repo, cacheRepository: cache)
        let toggleUseCase = ToggleFavouriteUseCase(repository: MockFavouritesRepository())
        let viewModel = makeViewModel(useCase: useCase, toggleUseCase: toggleUseCase)

        let target = viewModel.selectedSeason
        await viewModel.loadSeason(target)

        if case .loaded(let result) = viewModel.stateForSeason(target) {
            #expect(result.anime.count == 1)
        } else {
            Issue.record("Expected loaded state")
        }
    }

    @Test("Transitions to error on failure")
    func transitionsToError() async {
        struct TestError: Error, LocalizedError {
            var errorDescription: String? { "Network failed" }
        }
        let repo = MockAnimeRepository()
        repo.result = .failure(TestError())
        let cache = MockSeasonCacheRepository()
        let useCase = FetchSimulcastSeasonUseCase(repository: repo, cacheRepository: cache)
        let toggleUseCase = ToggleFavouriteUseCase(repository: MockFavouritesRepository())
        let viewModel = makeViewModel(useCase: useCase, toggleUseCase: toggleUseCase)

        let target = viewModel.selectedSeason
        await viewModel.loadSeason(target)

        if case .error(let message) = viewModel.stateForSeason(target) {
            #expect(message == "Network failed")
        } else {
            Issue.record("Expected error state")
        }
    }

    @Test("Shows cache banner when data is stale")
    func showsCacheBanner() async {
        struct TestError: Error {}
        let repo = MockAnimeRepository()
        repo.result = .failure(TestError())
        let cache = MockSeasonCacheRepository()
        let staleDate = Calendar.current.date(byAdding: .day, value: -5, to: Date())!
        let cachedSeason = SimulcastSeason(season: .winter, year: 2026, anime: [], fetchedAt: staleDate)
        await cache.cacheSeason(cachedSeason)
        let useCase = FetchSimulcastSeasonUseCase(repository: repo, cacheRepository: cache)
        let toggleUseCase = ToggleFavouriteUseCase(repository: MockFavouritesRepository())
        let viewModel = makeViewModel(useCase: useCase, toggleUseCase: toggleUseCase)

        let target = viewModel.selectedSeason
        await viewModel.loadSeason(target)

        #expect(viewModel.isShowingCacheBanner(for: target) == true)
    }

    @Test("Cache banner hidden on fresh network data")
    func cacheBannerHiddenOnFreshData() async {
        let season = SimulcastSeason(season: .winter, year: 2026, anime: [], fetchedAt: Date())
        let repo = MockAnimeRepository()
        repo.result = .success(season)
        let cache = MockSeasonCacheRepository()
        let useCase = FetchSimulcastSeasonUseCase(repository: repo, cacheRepository: cache)
        let toggleUseCase = ToggleFavouriteUseCase(repository: MockFavouritesRepository())
        let viewModel = makeViewModel(useCase: useCase, toggleUseCase: toggleUseCase)

        let target = viewModel.selectedSeason
        await viewModel.loadSeason(target)

        #expect(viewModel.isShowingCacheBanner(for: target) == false)
    }
}
