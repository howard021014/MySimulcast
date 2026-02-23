import Foundation

enum BrowseState {
    case idle
    case loading
    case loaded(SimulcastSeason)
    case error(String)
}

@Observable final class SimulcastBrowseViewModel {
    var browseState: BrowseState = .idle
    var currentSeason: Season
    var currentYear: Int

    private var favouriteIDs: Set<Int> = []

    var anime: [Anime] {
        guard case .loaded(let simulcastSeason) = browseState else { return [] }
        return simulcastSeason.anime.map { anime in
            var copy = anime
            copy.isFavourited = favouriteIDs.contains(anime.id)
            return copy
        }
    }

    var fetchedAt: Date? {
        guard case .loaded(let simulcastSeason) = browseState else { return nil }
        return simulcastSeason.fetchedAt
    }

    private let useCase: FetchSimulcastSeasonUseCase
    private let toggleUseCase: ToggleFavouriteUseCase

    init(useCase: FetchSimulcastSeasonUseCase, toggleUseCase: ToggleFavouriteUseCase) {
        self.useCase = useCase
        self.toggleUseCase = toggleUseCase
        let (season, year) = FetchSimulcastSeasonUseCase.currentSimulcastSeason()
        self.currentSeason = season
        self.currentYear = year
    }

    func loadSeason() async {
        browseState = .loading
        do {
            async let season = useCase.execute(season: currentSeason, year: currentYear)
            async let ids = toggleUseCase.loadFavouriteIDs()
            let (result, loadedIDs) = try await (season, ids)
            favouriteIDs = loadedIDs
            browseState = .loaded(result)
        } catch {
            browseState = .error(error.localizedDescription)
        }
    }

    func refresh() async {
        await loadSeason()
    }

    func toggleFavourite(anime: Anime) async {
        do {
            let newState = try await toggleUseCase.execute(
                animeID: anime.id,
                currentlyFavourited: favouriteIDs.contains(anime.id)
            )
            if newState {
                favouriteIDs.insert(anime.id)
            } else {
                favouriteIDs.remove(anime.id)
            }
        } catch {
            // Favourite toggle failures are silent — persistence errors are non-critical
        }
    }
}
