import Foundation
import SwiftUI

enum BrowseState {
    case idle
    case loading
    case loaded(SimulcastSeason)
    case error(String)
}

@Observable final class SimulcastBrowseViewModel {
    var seasons: [SeasonIdentifier]
    var selectedSeason: SeasonIdentifier
    var seasonStates: [SeasonIdentifier: BrowseState] = [:]

    private var retrySchedulers: [SeasonIdentifier: RetryScheduler] = [:]

    private let useCase: FetchSimulcastSeasonUseCase
    private let manageNotificationsUseCase: ManageNotificationsUseCase
    private let networkStatus: NetworkStatusProviding
    let favouriteManager: FavouriteManager

    init(
        useCase: FetchSimulcastSeasonUseCase,
        manageNotificationsUseCase: ManageNotificationsUseCase,
        networkStatus: NetworkStatusProviding,
        favouriteManager: FavouriteManager
    ) {
        self.useCase = useCase
        self.manageNotificationsUseCase = manageNotificationsUseCase
        self.networkStatus = networkStatus
        self.favouriteManager = favouriteManager
        let (season, year) = Season.current()
        let current = SeasonIdentifier(season: season, year: year)
        let persisted = Self.loadPersistedSeasons()
        if let persisted, persisted.first == current {
            self.seasons = persisted
        } else if let persisted, !persisted.contains(current) {
            var updated = [current] + persisted
            if updated.count > 4 { updated = Array(updated.prefix(4)) }
            self.seasons = updated
            Self.saveSeasons(updated)
        } else {
            self.seasons = [current]
            Self.saveSeasons([current])
        }
        self.selectedSeason = current
    }

    func stateForSeason(_ id: SeasonIdentifier) -> BrowseState {
        seasonStates[id] ?? .idle
    }

    func anime(for id: SeasonIdentifier) -> [Anime] {
        guard case .loaded(let simulcastSeason) = seasonStates[id] else { return [] }
        return simulcastSeason.anime.map { anime in
            var copy = anime
            copy.isFavourited = favouriteManager.isFavourited(id: anime.id)
            return copy
        }
    }

    func isShowingCacheBanner(for id: SeasonIdentifier) -> Bool {
        guard case .loaded(let simulcastSeason) = seasonStates[id] else { return false }
        let fourDaysAgo = Calendar.current.date(byAdding: .day, value: -4, to: Date())!
        return simulcastSeason.fetchedAt < fourDaysAgo
    }

    func fetchedAt(for id: SeasonIdentifier) -> Date? {
        guard case .loaded(let simulcastSeason) = seasonStates[id] else { return nil }
        return simulcastSeason.fetchedAt
    }

    func loadSeason(_ id: SeasonIdentifier) async {
        if case .loading = seasonStates[id] { return }
        if case .loaded = seasonStates[id] { return }

        seasonStates[id] = .loading
        do {
            async let fetchResult = useCase.execute(season: id.season, year: id.year)
            async let _ = favouriteManager.loadFavouriteIDs()
            let result = try await fetchResult
            seasonStates[id] = .loaded(result.season)
            if !result.isFromCache {
                retrySchedulers[id] = nil
            }
        } catch {
            seasonStates[id] = .error(error.localizedDescription)
        }
    }

    func retryLoadSeason(_ id: SeasonIdentifier) async {
        seasonStates[id] = nil
        var scheduler = retrySchedulers[id] ?? RetryScheduler()
        let delay = scheduler.nextDelay()
        retrySchedulers[id] = scheduler
        try? await Task.sleep(for: .seconds(delay))
        await loadSeason(id)
    }

    func toggleFavourite(anime: Anime) async {
        let currentAnime = self.anime(for: selectedSeason)
        let sortOrder = currentAnime.firstIndex(where: { $0.id == anime.id }) ?? Int.max
        await favouriteManager.toggleFavourite(
            anime: anime,
            season: selectedSeason.season,
            year: selectedSeason.year,
            sortOrder: sortOrder
        )
    }

    func checkStaleAndRefresh() async {
        guard let fetchedAt = fetchedAt(for: selectedSeason) else { return }
        let fourDaysAgo = Calendar.current.date(byAdding: .day, value: -4, to: Date())!
        guard fetchedAt < fourDaysAgo else { return }
        seasonStates[selectedSeason] = nil
        await loadSeason(selectedSeason)
        let isNotificationsEnabled = UserDefaults.standard.bool(forKey: "notificationsEnabled")
        if isNotificationsEnabled {
            let currentAnime = anime(for: selectedSeason)
            await manageNotificationsUseCase.reSyncIfNeeded(
                currentAnime: currentAnime, season: selectedSeason.season, year: selectedSeason.year
            )
        }
    }

    func refreshSeasonListIfNeeded() {
        let (current, year) = Season.current()
        let expected = SeasonIdentifier(season: current, year: year)
        if seasons.first != expected {
            seasons.insert(expected, at: 0)
            if seasons.count > 4 { seasons = Array(seasons.prefix(4)) }
            selectedSeason = expected
            Self.saveSeasons(seasons)
        }
    }

    private static let seasonsKey = "knownSimulcastSeasons"

    private static func saveSeasons(_ seasons: [SeasonIdentifier]) {
        if let data = try? JSONEncoder().encode(seasons) {
            UserDefaults.standard.set(data, forKey: seasonsKey)
        }
    }

    private static func loadPersistedSeasons() -> [SeasonIdentifier]? {
        guard let data = UserDefaults.standard.data(forKey: seasonsKey) else { return nil }
        return try? JSONDecoder().decode([SeasonIdentifier].self, from: data)
    }
}
