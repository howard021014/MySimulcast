import Testing
import Foundation
@testable import MySimulcast

private func makeAnime(id: Int, title: String = "Anime", schedule: AiringSchedule? = nil) -> Anime {
    Anime(id: id, title: title, coverImageURL: nil, thumbnailImageURL: nil,
          description: nil, airingSchedule: schedule, isFavourited: true)
}

private func makeFavourite(id: Int, season: Season = .winter, year: Int = 2026, schedule: AiringSchedule? = nil) -> FavouriteAnime {
    FavouriteAnime(anime: makeAnime(id: id, schedule: schedule), season: season, year: year, addedAt: Date())
}

@Suite("FavouritesViewModel")
struct FavouritesViewModelTests {

    private func makeViewModel(favourites: [FavouriteAnime] = []) -> FavouritesViewModel {
        let repo = MockFavouritesRepository()
        repo.storedFavourites = favourites
        return FavouritesViewModel(
            getUseCase: GetFavouritesUseCase(repository: repo),
            toggleUseCase: ToggleFavouriteUseCase(repository: repo)
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

    @Test("availableFilters returns only .all for single season")
    func availableFiltersSingleSeason() async {
        let favourites = [makeFavourite(id: 1), makeFavourite(id: 2)]
        let viewModel = makeViewModel(favourites: favourites)
        await viewModel.load()

        #expect(viewModel.availableFilters == [.all])
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

    @Test("No schedule data shows no schedule info")
    func noScheduleInfo() async {
        let (currentSeason, currentYear) = Season.current()
        let favourites = [makeFavourite(id: 1, season: currentSeason, year: currentYear)]
        let viewModel = makeViewModel(favourites: favourites)
        await viewModel.load()

        let text = viewModel.displayedAnime[0].scheduleText
        #expect(text == "No schedule info")
    }
}
