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
    var showNotificationPrompt = false
    var showDeniedBanner = false

    private var favouriteIDs: Set<Int> = []
    private var pendingNotificationAnime: Anime?
    private var retrySchedulers: [SeasonIdentifier: RetryScheduler] = [:]

    private var notificationPromptDismissCount: Int {
        get { UserDefaults.standard.integer(forKey: "notificationPromptDismissCount") }
        set { UserDefaults.standard.set(newValue, forKey: "notificationPromptDismissCount") }
    }

    private var isNotificationsEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "notificationsEnabled") }
        set { UserDefaults.standard.set(newValue, forKey: "notificationsEnabled") }
    }

    private let useCase: FetchSimulcastSeasonUseCase
    private let toggleUseCase: ToggleFavouriteUseCase
    private let scheduleNotificationUseCase: ScheduleNotificationUseCase
    private let manageNotificationsUseCase: ManageNotificationsUseCase
    private let networkStatus: NetworkStatusProviding

    init(
        useCase: FetchSimulcastSeasonUseCase,
        toggleUseCase: ToggleFavouriteUseCase,
        scheduleNotificationUseCase: ScheduleNotificationUseCase,
        manageNotificationsUseCase: ManageNotificationsUseCase,
        networkStatus: NetworkStatusProviding
    ) {
        self.useCase = useCase
        self.toggleUseCase = toggleUseCase
        self.scheduleNotificationUseCase = scheduleNotificationUseCase
        self.manageNotificationsUseCase = manageNotificationsUseCase
        self.networkStatus = networkStatus
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
            copy.isFavourited = favouriteIDs.contains(anime.id)
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
            async let ids = toggleUseCase.loadFavouriteIDs()
            let (result, loadedIDs) = try await (fetchResult, ids)
            favouriteIDs = loadedIDs
            seasonStates[id] = .loaded(result.season)
            if !result.isFromCache {
                retrySchedulers[id] = nil
            }
        } catch {
            seasonStates[id] = .error(error.localizedDescription)
        }
    }

    func refreshFavouriteIDs() async {
        favouriteIDs = (try? await toggleUseCase.loadFavouriteIDs()) ?? favouriteIDs
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
        do {
            let newState = try await toggleUseCase.execute(
                anime: anime,
                season: selectedSeason.season,
                year: selectedSeason.year,
                sortOrder: sortOrder,
                currentlyFavourited: favouriteIDs.contains(anime.id)
            )
            if newState {
                favouriteIDs.insert(anime.id)
                await handleFavourited(anime: anime)
            } else {
                favouriteIDs.remove(anime.id)
                await scheduleNotificationUseCase.cancelForAnime(id: anime.id)
            }
        } catch {}
    }

    func onNotificationPromptEnable() async {
        guard let anime = pendingNotificationAnime else { return }
        let granted = (try? await scheduleNotificationUseCase.requestAuthorization()) ?? false
        if granted {
            isNotificationsEnabled = true
            await scheduleNotificationUseCase.scheduleForAnime(
                anime: anime, season: selectedSeason.season, year: selectedSeason.year
            )
        }
        pendingNotificationAnime = nil
        showNotificationPrompt = false
    }

    func onNotificationPromptDismiss() {
        notificationPromptDismissCount += 1
        pendingNotificationAnime = nil
        showNotificationPrompt = false
    }

    func checkStaleAndRefresh() async {
        guard let fetchedAt = fetchedAt(for: selectedSeason) else { return }
        let fourDaysAgo = Calendar.current.date(byAdding: .day, value: -4, to: Date())!
        guard fetchedAt < fourDaysAgo else { return }
        seasonStates[selectedSeason] = nil
        await loadSeason(selectedSeason)
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

    private func handleFavourited(anime: Anime) async {
        let isSimulcasting = anime.airingSchedule != nil
        guard isSimulcasting else { return }

        let status = await scheduleNotificationUseCase.authorizationStatus()
        switch status {
        case .notDetermined:
            if notificationPromptDismissCount < 2 {
                pendingNotificationAnime = anime
                showNotificationPrompt = true
            }
        case .authorized, .provisional:
            isNotificationsEnabled = true
            await scheduleNotificationUseCase.scheduleForAnime(
                anime: anime, season: selectedSeason.season, year: selectedSeason.year
            )
        case .denied:
            showDeniedBanner = true
        }
    }
}
