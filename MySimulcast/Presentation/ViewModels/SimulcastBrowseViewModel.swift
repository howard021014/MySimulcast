import Foundation
import SwiftUI

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
    var showNotificationPrompt = false
    var showDeniedBanner = false

    private var favouriteIDs: Set<Int> = []
    private var pendingNotificationAnime: Anime?

    private var notificationPromptDismissCount: Int {
        get { UserDefaults.standard.integer(forKey: "notificationPromptDismissCount") }
        set { UserDefaults.standard.set(newValue, forKey: "notificationPromptDismissCount") }
    }

    private var isNotificationsEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "notificationsEnabled") }
        set { UserDefaults.standard.set(newValue, forKey: "notificationsEnabled") }
    }

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
    private let scheduleNotificationUseCase: ScheduleNotificationUseCase
    private let manageNotificationsUseCase: ManageNotificationsUseCase

    init(
        useCase: FetchSimulcastSeasonUseCase,
        toggleUseCase: ToggleFavouriteUseCase,
        scheduleNotificationUseCase: ScheduleNotificationUseCase,
        manageNotificationsUseCase: ManageNotificationsUseCase
    ) {
        self.useCase = useCase
        self.toggleUseCase = toggleUseCase
        self.scheduleNotificationUseCase = scheduleNotificationUseCase
        self.manageNotificationsUseCase = manageNotificationsUseCase
        let (season, year) = Season.current()
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

    func toggleFavourite(anime: Anime) async {
        do {
            let newState = try await toggleUseCase.execute(
                anime: anime,
                season: currentSeason,
                year: currentYear,
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
            await scheduleNotificationUseCase.scheduleForAnime(anime: anime, season: currentSeason, year: currentYear)
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
        guard let fetchedAt else { return }
        let fourDaysAgo = Calendar.current.date(byAdding: .day, value: -4, to: Date())!
        guard fetchedAt < fourDaysAgo else { return }
        await loadSeason()
        if isNotificationsEnabled {
            await manageNotificationsUseCase.reSyncIfNeeded(currentAnime: anime, season: currentSeason, year: currentYear)
        }
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
            await scheduleNotificationUseCase.scheduleForAnime(anime: anime, season: currentSeason, year: currentYear)
        case .denied:
            showDeniedBanner = true
        }
    }
}
