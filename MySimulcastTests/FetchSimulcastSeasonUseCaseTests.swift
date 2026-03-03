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
        let useCase = FetchSimulcastSeasonUseCase(repository: repo)

        let result = try await useCase.execute(season: .winter, year: 2026)

        #expect(result.season == expected.season)
        #expect(result.year == expected.year)
    }

    @Test("Propagates errors from repository")
    func propagatesErrors() async {
        struct TestError: Error {}
        let repo = MockAnimeRepository()
        repo.result = .failure(TestError())
        let useCase = FetchSimulcastSeasonUseCase(repository: repo)

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

@Suite("SimulcastBrowseViewModel")
struct SimulcastBrowseViewModelTests {

    private func makeViewModel(useCase: FetchSimulcastSeasonUseCase, toggleUseCase: ToggleFavouriteUseCase) -> SimulcastBrowseViewModel {
        let service = MockNotificationService()
        let repo = MockFavouritesRepository()
        let scheduleUseCase = ScheduleNotificationUseCase(notificationService: service, isNotificationsEnabled: { true })
        let manageUseCase = ManageNotificationsUseCase(scheduleUseCase: scheduleUseCase, favouritesRepository: repo, notificationService: service)
        return SimulcastBrowseViewModel(useCase: useCase, toggleUseCase: toggleUseCase, scheduleNotificationUseCase: scheduleUseCase, manageNotificationsUseCase: manageUseCase)
    }

    @Test("Starts idle")
    func startsIdle() {
        let repo = MockAnimeRepository()
        let useCase = FetchSimulcastSeasonUseCase(repository: repo)
        let toggleUseCase = ToggleFavouriteUseCase(repository: MockFavouritesRepository())
        let viewModel = makeViewModel(useCase: useCase, toggleUseCase: toggleUseCase)

        if case .idle = viewModel.browseState { } else {
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
        let useCase = FetchSimulcastSeasonUseCase(repository: repo)
        let toggleUseCase = ToggleFavouriteUseCase(repository: MockFavouritesRepository())
        let viewModel = makeViewModel(useCase: useCase, toggleUseCase: toggleUseCase)

        await viewModel.loadSeason()

        if case .loaded(let result) = viewModel.browseState {
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
        let useCase = FetchSimulcastSeasonUseCase(repository: repo)
        let toggleUseCase = ToggleFavouriteUseCase(repository: MockFavouritesRepository())
        let viewModel = makeViewModel(useCase: useCase, toggleUseCase: toggleUseCase)

        await viewModel.loadSeason()

        if case .error(let message) = viewModel.browseState {
            #expect(message == "Network failed")
        } else {
            Issue.record("Expected error state")
        }
    }
}
