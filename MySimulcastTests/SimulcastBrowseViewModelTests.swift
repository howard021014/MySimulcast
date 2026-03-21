import Testing
import Foundation
@testable import MySimulcast

private func makeAnime(id: Int, title: String = "Anime", schedule: AiringSchedule? = nil) -> Anime {
    Anime(id: id, title: title, coverImageURL: nil, thumbnailImageURL: nil,
          description: nil, airingSchedule: schedule, season: nil, seasonYear: nil, isFavourited: false)
}

@Suite("SimulcastBrowseViewModel")
struct SimulcastBrowseViewModelTests {

    private func makeViewModel(
        animeResult: Result<SimulcastSeason, Error>? = nil
    ) -> (SimulcastBrowseViewModel, MockAnimeRepository) {
        UserDefaults.standard.removeObject(forKey: "knownSimulcastSeasons")
        let repo = MockAnimeRepository()
        if let animeResult {
            repo.result = animeResult
        }
        let cache = MockSeasonCacheRepository()
        let favRepo = MockFavouritesRepository()
        let notifService = MockNotificationService()
        let networkStatus = MockNetworkStatus()

        let fetchUseCase = FetchSimulcastSeasonUseCase(repository: repo, cacheRepository: cache)
        let toggleUseCase = ToggleFavouriteUseCase(repository: favRepo)
        let scheduleUseCase = ScheduleNotificationUseCase(notificationService: notifService, isNotificationsEnabled: { true })
        let manageUseCase = ManageNotificationsUseCase(
            scheduleUseCase: scheduleUseCase,
            favouritesRepository: favRepo,
            notificationService: notifService
        )

        let vm = SimulcastBrowseViewModel(
            useCase: fetchUseCase,
            toggleUseCase: toggleUseCase,
            scheduleNotificationUseCase: scheduleUseCase,
            manageNotificationsUseCase: manageUseCase,
            networkStatus: networkStatus
        )
        return (vm, repo)
    }

    @Test("seasons list starts with only current season")
    func seasonsCountInitial() {
        let (vm, _) = makeViewModel()
        #expect(vm.seasons.count == 1)
    }

    @Test("seasons stay at 1 after fresh network fetch")
    func seasonsStayAfterFetch() async {
        let season = SimulcastSeason(season: .winter, year: 2026, anime: [], fetchedAt: Date())
        let (vm, _) = makeViewModel(animeResult: .success(season))

        await vm.loadSeason(vm.seasons[0])

        #expect(vm.seasons.count == 1)
    }

    @Test("first season matches current season")
    func firstSeasonIsCurrent() {
        let (vm, _) = makeViewModel()
        let (currentSeason, currentYear) = Season.current()
        #expect(vm.seasons[0].season == currentSeason)
        #expect(vm.seasons[0].year == currentYear)
    }

    @Test("selectedSeason defaults to first season")
    func selectedSeasonDefault() {
        let (vm, _) = makeViewModel()
        #expect(vm.selectedSeason == vm.seasons[0])
    }

    @Test("all season states start as idle")
    func initialStatesAreIdle() {
        let (vm, _) = makeViewModel()
        for season in vm.seasons {
            guard case .idle = vm.stateForSeason(season) else {
                Issue.record("Expected idle state for \(season.label)")
                return
            }
        }
    }

    @Test("loadSeason sets state to loaded for that season only")
    func loadSeasonSetsLoaded() async {
        let season = SimulcastSeason(season: .winter, year: 2026, anime: [makeAnime(id: 1)], fetchedAt: Date())
        let (vm, _) = makeViewModel(animeResult: .success(season))

        let target = vm.seasons[0]
        await vm.loadSeason(target)

        guard case .loaded = vm.stateForSeason(target) else {
            Issue.record("Expected loaded state")
            return
        }

        // Other seasons remain idle
        for other in vm.seasons.dropFirst() {
            guard case .idle = vm.stateForSeason(other) else {
                Issue.record("Expected idle state for \(other.label)")
                return
            }
        }
    }

    @Test("loadSeason is a no-op for already loaded season")
    func loadSeasonNoOpWhenLoaded() async {
        let season = SimulcastSeason(season: .winter, year: 2026, anime: [makeAnime(id: 1)], fetchedAt: Date())
        let (vm, repo) = makeViewModel(animeResult: .success(season))

        let target = vm.seasons[0]
        await vm.loadSeason(target)

        // Change what repo would return
        let different = SimulcastSeason(season: .winter, year: 2026, anime: [makeAnime(id: 99)], fetchedAt: Date())
        repo.result = .success(different)

        // Load again — should be no-op
        await vm.loadSeason(target)

        let anime = vm.anime(for: target)
        #expect(anime.count == 1)
        #expect(anime[0].id == 1)
    }

    @Test("anime returns data with favourite state applied")
    func animeWithFavouriteState() async {
        let season = SimulcastSeason(season: .winter, year: 2026, anime: [makeAnime(id: 1), makeAnime(id: 2)], fetchedAt: Date())
        let (vm, _) = makeViewModel(animeResult: .success(season))

        let target = vm.seasons[0]
        await vm.loadSeason(target)

        let animeList = vm.anime(for: target)
        #expect(animeList.count == 2)
    }

    @Test("error state on fetch failure")
    func errorState() async {
        let (vm, _) = makeViewModel(animeResult: .failure(NSError(domain: "test", code: 1)))

        let target = vm.seasons[0]
        await vm.loadSeason(target)

        guard case .error = vm.stateForSeason(target) else {
            Issue.record("Expected error state")
            return
        }
    }

    @Test("refreshSeasonListIfNeeded is a no-op when season hasn't changed")
    func refreshNoOp() {
        let (vm, _) = makeViewModel()
        let originalCount = vm.seasons.count
        let originalFirst = vm.seasons[0]

        vm.refreshSeasonListIfNeeded()

        #expect(vm.seasons.count == originalCount)
        #expect(vm.seasons[0] == originalFirst)
    }
}
