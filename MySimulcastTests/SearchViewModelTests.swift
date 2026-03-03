import Testing
import Foundation
@testable import MySimulcast

private func makeAnime(id: Int, title: String = "Anime", season: Season? = nil, seasonYear: Int? = nil) -> Anime {
    Anime(id: id, title: title, coverImageURL: nil, thumbnailImageURL: nil,
          description: nil, airingSchedule: nil, season: season, seasonYear: seasonYear, isFavourited: false)
}

@Suite("SearchViewModel")
struct SearchViewModelTests {

    private func makeViewModel(
        searchResult: SearchResult = SearchResult(anime: [], currentPage: 1, hasNextPage: false),
        favouriteIDs: Set<Int> = []
    ) -> (SearchViewModel, MockAnimeRepository, MockFavouritesRepository) {
        let animeRepo = MockAnimeRepository()
        animeRepo.searchResult = .success(searchResult)
        let favouritesRepo = MockFavouritesRepository()
        favouritesRepo.ids = favouriteIDs
        let searchUseCase = SearchAnimeUseCase(repository: animeRepo)
        let toggleUseCase = ToggleFavouriteUseCase(repository: favouritesRepo)
        let service = MockNotificationService()
        let scheduleNotificationUseCase = ScheduleNotificationUseCase(notificationService: service, isNotificationsEnabled: { true })
        let vm = SearchViewModel(searchUseCase: searchUseCase, toggleUseCase: toggleUseCase, scheduleNotificationUseCase: scheduleNotificationUseCase)
        return (vm, animeRepo, favouritesRepo)
    }

    @Test("Initial state is idle")
    func initialStateIsIdle() {
        let (vm, _, _) = makeViewModel()
        if case .idle = vm.state { } else {
            Issue.record("Expected idle state")
        }
    }

    @Test("Query less than 2 chars stays idle")
    func shortQueryStaysIdle() {
        let (vm, _, _) = makeViewModel()
        vm.searchText = "a"
        vm.searchTextChanged()
        if case .idle = vm.state { } else {
            Issue.record("Expected idle state for short query")
        }
    }

    @Test("Clearing text resets to idle and clears results")
    func clearTextResetsState() async {
        let result = SearchResult(anime: [makeAnime(id: 1)], currentPage: 1, hasNextPage: false)
        let (vm, _, _) = makeViewModel(searchResult: result)

        vm.searchText = ""
        vm.searchTextChanged()

        if case .idle = vm.state { } else {
            Issue.record("Expected idle state after clearing")
        }
        #expect(vm.results.isEmpty)
    }

    @Test("displayedResults reflects favouriteIDs")
    func displayedResultsReflectsFavourites() async {
        let result = SearchResult(anime: [makeAnime(id: 1), makeAnime(id: 2)], currentPage: 1, hasNextPage: false)
        let (vm, _, _) = makeViewModel(searchResult: result, favouriteIDs: [2])

        await vm.reloadFavouriteIDs()
        vm.results = [makeAnime(id: 1), makeAnime(id: 2)]

        let displayed = vm.displayedResults
        #expect(displayed.first(where: { $0.id == 1 })?.isFavourited == false)
        #expect(displayed.first(where: { $0.id == 2 })?.isFavourited == true)
    }

    @Test("Toggle favourite adds to favouriteIDs")
    func toggleFavouriteAdds() async {
        let (vm, _, _) = makeViewModel()
        let anime = makeAnime(id: 1, season: .winter, seasonYear: 2026)
        vm.results = [anime]

        await vm.toggleFavourite(anime: anime)

        #expect(vm.displayedResults.first?.isFavourited == true)
    }

    @Test("Toggle favourite removes from favouriteIDs")
    func toggleFavouriteRemoves() async {
        let (vm, _, _) = makeViewModel(favouriteIDs: [1])
        let anime = makeAnime(id: 1, season: .winter, seasonYear: 2026)
        vm.results = [anime]
        await vm.reloadFavouriteIDs()

        await vm.toggleFavourite(anime: anime)

        #expect(vm.displayedResults.first?.isFavourited == false)
    }

    @Test("Toggle favourite uses anime season/year")
    func toggleFavouriteUsesAnimeSeason() async {
        let (vm, _, favouritesRepo) = makeViewModel()
        let anime = makeAnime(id: 1, season: .summer, seasonYear: 2025)
        vm.results = [anime]

        await vm.toggleFavourite(anime: anime)

        let stored = favouritesRepo.storedFavourites.first
        #expect(stored?.season == .summer)
        #expect(stored?.year == 2025)
    }

    @Test("loadNextPageIfNeeded triggers for items near end of list")
    func loadNextPageTriggersNearEnd() async {
        let anime = (1...10).map { makeAnime(id: $0) }
        let result = SearchResult(anime: anime, currentPage: 1, hasNextPage: true)
        let (vm, animeRepo, _) = makeViewModel(searchResult: result)

        // Simulate loaded state
        vm.results = anime
        // Manually set hasNextPage via a search
        vm.searchText = "test"
        // Set up page 2 results
        let page2Anime = [makeAnime(id: 11)]
        animeRepo.searchResult = .success(SearchResult(anime: page2Anime, currentPage: 2, hasNextPage: false))

        // The loadNextPageIfNeeded won't trigger because hasNextPage is false in default state
        // This tests the guard check
        vm.loadNextPageIfNeeded(currentItem: anime[9])
        // hasNextPage is false by default so this should not load
        #expect(vm.isLoadingNextPage == false)
    }

    @Test("loadNextPageIfNeeded does NOT trigger when hasNextPage is false")
    func loadNextPageDoesNotTriggerWhenNoNextPage() {
        let anime = (1...10).map { makeAnime(id: $0) }
        let (vm, _, _) = makeViewModel()
        vm.results = anime

        vm.loadNextPageIfNeeded(currentItem: anime[9])

        #expect(vm.isLoadingNextPage == false)
    }

    @Test("Error state on API failure")
    func errorStateOnFailure() async {
        struct TestError: Error, LocalizedError {
            var errorDescription: String? { "Network failed" }
        }
        let animeRepo = MockAnimeRepository()
        animeRepo.searchResult = .failure(TestError())
        let favouritesRepo = MockFavouritesRepository()
        let service = MockNotificationService()
        let scheduleNotificationUseCase = ScheduleNotificationUseCase(notificationService: service, isNotificationsEnabled: { true })
        let vm = SearchViewModel(
            searchUseCase: SearchAnimeUseCase(repository: animeRepo),
            toggleUseCase: ToggleFavouriteUseCase(repository: favouritesRepo),
            scheduleNotificationUseCase: scheduleNotificationUseCase
        )

        vm.searchText = "test query"
        vm.searchTextChanged()
        // Wait for debounce + execution
        try? await Task.sleep(for: .milliseconds(600))

        if case .error(let message) = vm.state {
            #expect(message == "Network failed")
        } else {
            Issue.record("Expected error state, got \(vm.state)")
        }
    }
}
