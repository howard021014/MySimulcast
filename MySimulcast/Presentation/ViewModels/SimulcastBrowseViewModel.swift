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

    var anime: [Anime] {
        if case .loaded(let simulcastSeason) = browseState {
            return simulcastSeason.anime
        }
        return []
    }

    var fetchedAt: Date? {
        if case .loaded(let simulcastSeason) = browseState {
            return simulcastSeason.fetchedAt
        }
        return nil
    }

    private let useCase: FetchSimulcastSeasonUseCase

    init(useCase: FetchSimulcastSeasonUseCase) {
        self.useCase = useCase
        let (season, year) = FetchSimulcastSeasonUseCase.currentSimulcastSeason()
        self.currentSeason = season
        self.currentYear = year
    }

    func loadSeason() async {
        browseState = .loading
        do {
            let result = try await useCase.execute(season: currentSeason, year: currentYear)
            browseState = .loaded(result)
        } catch {
            browseState = .error(error.localizedDescription)
        }
    }

    func refresh() async {
        await loadSeason()
    }
}
