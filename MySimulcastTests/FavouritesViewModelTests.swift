import Testing
import Foundation
@testable import MySimulcast

private func makeAnime(id: Int, title: String = "Anime", schedule: AiringSchedule? = nil) -> Anime {
    Anime(id: id, title: title, coverImageURL: nil, thumbnailImageURL: nil,
          description: nil, airingSchedule: schedule, season: nil, seasonYear: nil, isFavourited: true)
}

private func makeFavourite(id: Int, season: Season? = .winter, year: Int? = 2026, sortOrder: Int = 0, schedule: AiringSchedule? = nil) -> FavouriteAnime {
    FavouriteAnime(anime: makeAnime(id: id, schedule: schedule), season: season, year: year, addedAt: Date(), sortOrder: sortOrder)
}

@Suite("FavouritesViewModel")
struct FavouritesViewModelTests {

    private func makeViewModel(favourites: [FavouriteAnime] = []) -> FavouritesViewModel {
        let repo = MockFavouritesRepository()
        repo.storedFavourites = favourites
        let service = MockNotificationService()
        let scheduleUseCase = ScheduleNotificationUseCase(notificationService: service, isNotificationsEnabled: { true })
        return FavouritesViewModel(
            getUseCase: GetFavouritesUseCase(repository: repo),
            toggleUseCase: ToggleFavouriteUseCase(repository: repo),
            scheduleNotificationUseCase: scheduleUseCase
        )
    }

    @Test("State transitions: idle → loading → loaded")
    func stateTransitions() async {
        let viewModel = makeViewModel()
        guard case .idle = viewModel.state else {
            Issue.record("Expected idle initial state")
            return
        }
        await viewModel.load()
        guard case .loaded = viewModel.state else {
            Issue.record("Expected loaded state after load()")
            return
        }
    }

    @Test("displayedAnime reflects .all filter — returns everything")
    func displayedAnimeAllFilter() async {
        let favourites = [makeFavourite(id: 1), makeFavourite(id: 2)]
        let viewModel = makeViewModel(favourites: favourites)
        await viewModel.load()

        viewModel.selectedFilter = .all

        #expect(viewModel.displayedAnime.count == 2)
    }

    @Test("displayedAnime reflects season filter — returns subset")
    func displayedAnimeSeasonFilter() async {
        let favourites = [
            makeFavourite(id: 1, season: .winter, year: 2026),
            makeFavourite(id: 2, season: .spring, year: 2026)
        ]
        let viewModel = makeViewModel(favourites: favourites)
        await viewModel.load()

        viewModel.selectedFilter = .season(.winter, 2026)

        #expect(viewModel.displayedAnime.count == 1)
        #expect(viewModel.displayedAnime[0].anime.id == 1)
    }

    @Test("availableFilters derived correctly from loaded data")
    func availableFilters() async {
        let favourites = [
            makeFavourite(id: 1, season: .winter, year: 2026),
            makeFavourite(id: 2, season: .spring, year: 2026)
        ]
        let viewModel = makeViewModel(favourites: favourites)
        await viewModel.load()

        let filters = viewModel.availableFilters
        #expect(filters.count == 3) // .all + 2 season filters
        #expect(filters.contains(.all))
        #expect(filters.contains(.season(.winter, 2026)))
        #expect(filters.contains(.season(.spring, 2026)))
    }

    @Test("availableFilters includes season even for single season")
    func availableFiltersSingleSeason() async {
        let favourites = [makeFavourite(id: 1), makeFavourite(id: 2)]
        let viewModel = makeViewModel(favourites: favourites)
        await viewModel.load()

        #expect(viewModel.availableFilters == [.all, .season(.winter, 2026)])
    }

    @Test("toggleFavourite removes item from state optimistically")
    func toggleFavouriteRemovesOptimistically() async {
        let favourites = [makeFavourite(id: 1), makeFavourite(id: 2)]
        let viewModel = makeViewModel(favourites: favourites)
        await viewModel.load()

        await viewModel.toggleFavourite(anime: makeAnime(id: 1))

        #expect(viewModel.displayedAnime.count == 1)
        #expect(viewModel.displayedAnime[0].anime.id == 2)
    }

    @Test("Current season favourite with schedule shows episode info")
    func currentSeasonWithSchedule() async {
        let (currentSeason, currentYear) = Season.current()
        let schedule = AiringSchedule(nextEpisode: 5, nextAiringAt: Date())
        let favourites = [makeFavourite(id: 1, season: currentSeason, year: currentYear, schedule: schedule)]
        let viewModel = makeViewModel(favourites: favourites)
        await viewModel.load()

        let text = viewModel.displayedAnime[0].scheduleText
        #expect(text.contains("Ep"))
    }

    @Test("Past season favourite shows aired in text")
    func pastSeasonShowsAiredIn() async {
        let favourites = [makeFavourite(id: 1, season: .winter, year: 2025)]
        let viewModel = makeViewModel(favourites: favourites)
        await viewModel.load()

        let text = viewModel.displayedAnime[0].scheduleText
        #expect(text == "Aired in Winter 2025")
    }

    @Test("displayedAnime(for:) returns correct items for specific filter")
    func displayedAnimeForFilter() async {
        let favourites = [
            makeFavourite(id: 1, season: .winter, year: 2026),
            makeFavourite(id: 2, season: .spring, year: 2026),
            makeFavourite(id: 3, season: .winter, year: 2026)
        ]
        let viewModel = makeViewModel(favourites: favourites)
        await viewModel.load()

        let winterItems = viewModel.displayedAnime(for: .season(.winter, 2026))
        #expect(winterItems.count == 2)
        #expect(winterItems.allSatisfy { $0.anime.id == 1 || $0.anime.id == 3 })

        let springItems = viewModel.displayedAnime(for: .season(.spring, 2026))
        #expect(springItems.count == 1)
        #expect(springItems[0].anime.id == 2)

        let allItems = viewModel.displayedAnime(for: .all)
        #expect(allItems.count == 3)
    }

    @Test("No schedule data shows no schedule info")
    func noScheduleInfo() async {
        let (currentSeason, currentYear) = Season.current()
        let favourites = [makeFavourite(id: 1, season: currentSeason, year: currentYear)]
        let viewModel = makeViewModel(favourites: favourites)
        await viewModel.load()

        let text = viewModel.displayedAnime[0].scheduleText
        #expect(text == "No schedule info")
    }

    @Test("Nil-season anime only appears in .all filter")
    func nilSeasonOnlyInAll() async {
        let favourites = [
            makeFavourite(id: 1, season: nil, year: nil),
            makeFavourite(id: 2, season: .winter, year: 2026),
            makeFavourite(id: 3, season: .spring, year: 2026)
        ]
        let viewModel = makeViewModel(favourites: favourites)
        await viewModel.load()

        let allItems = viewModel.displayedAnime(for: .all)
        #expect(allItems.count == 3)
        #expect(allItems.contains(where: { $0.anime.id == 1 }))

        let winterItems = viewModel.displayedAnime(for: .season(.winter, 2026))
        #expect(!winterItems.contains(where: { $0.anime.id == 1 }))

        let springItems = viewModel.displayedAnime(for: .season(.spring, 2026))
        #expect(!springItems.contains(where: { $0.anime.id == 1 }))
    }

    @Test("availableFilters excludes nil-season items from season pills")
    func availableFiltersExcludesNilSeason() async {
        let favourites = [
            makeFavourite(id: 1, season: nil, year: nil),
            makeFavourite(id: 2, season: .winter, year: 2026),
            makeFavourite(id: 3, season: .spring, year: 2026)
        ]
        let viewModel = makeViewModel(favourites: favourites)
        await viewModel.load()

        let filters = viewModel.availableFilters
        #expect(filters.count == 3) // .all + winter + spring
        #expect(filters.contains(.all))
        #expect(filters.contains(.season(.winter, 2026)))
        #expect(filters.contains(.season(.spring, 2026)))
    }

    @Test("Items within a filter preserve sortOrder")
    func sortOrderPreserved() async {
        let favourites = [
            makeFavourite(id: 1, season: .winter, year: 2026, sortOrder: 2),
            makeFavourite(id: 2, season: .winter, year: 2026, sortOrder: 0),
            makeFavourite(id: 3, season: .winter, year: 2026, sortOrder: 1)
        ]
        let viewModel = makeViewModel(favourites: favourites)
        await viewModel.load()

        let winterItems = viewModel.displayedAnime(for: .season(.winter, 2026))
        #expect(winterItems.map(\.anime.id) == [2, 3, 1])
    }

    @Test("Unfavouriting only anime in selected season filter resets to .all")
    func unfavouritingLastInFilterResetsToAll() async {
        let (currentSeason, currentYear) = Season.current()
        let schedule = AiringSchedule(nextEpisode: 5, nextAiringAt: Date())
        let favourites = [
            makeFavourite(id: 1, season: currentSeason, year: currentYear, sortOrder: 0, schedule: schedule),
            makeFavourite(id: 2, season: .winter, year: 2025, sortOrder: 0)
        ]
        let viewModel = makeViewModel(favourites: favourites)
        await viewModel.load()

        // Select the past-season filter
        viewModel.selectedFilter = .season(.winter, 2025)
        #expect(viewModel.displayedAnime.count == 1)
        #expect(viewModel.displayedAnime[0].anime.id == 2)

        // Unfavourite the only anime in that filter
        await viewModel.toggleFavourite(anime: makeAnime(id: 2))

        // Filter should reset to .all and show remaining favourites
        let (currentSeason2, currentYear2) = Season.current()
        #expect(viewModel.selectedFilter == .all)
        #expect(viewModel.availableFilters == [.all, .season(currentSeason2, currentYear2)])
        #expect(viewModel.displayedAnime.count == 1)
        #expect(viewModel.displayedAnime[0].anime.id == 1)
    }

    @Test("Nil-season anime shows 'No season info' schedule text")
    func nilSeasonScheduleText() async {
        let favourites = [makeFavourite(id: 1, season: nil, year: nil)]
        let viewModel = makeViewModel(favourites: favourites)
        await viewModel.load()

        let text = viewModel.displayedAnime[0].scheduleText
        #expect(text == "No season info")
    }
}
