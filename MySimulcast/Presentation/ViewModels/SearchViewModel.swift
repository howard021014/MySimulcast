import Foundation
import SwiftUI

enum SearchState {
    case idle
    case loading
    case loaded
    case error(String)
}

@Observable final class SearchViewModel {
    var searchText = ""
    var state: SearchState = .idle
    var results: [Anime] = []
    var isLoadingNextPage = false
    var showNotificationPrompt = false
    var showDeniedBanner = false

    var displayedResults: [Anime] {
        results.map { anime in
            var copy = anime
            copy.isFavourited = favouriteIDs.contains(anime.id)
            return copy
        }
    }

    private var favouriteIDs: Set<Int> = []
    private var currentPage = 1
    private var hasNextPage = false
    private var lastSearchedQuery = ""
    private var searchTask: Task<Void, Never>?
    private var pendingNotificationAnime: Anime?

    private var notificationPromptDismissCount: Int {
        get { UserDefaults.standard.integer(forKey: "notificationPromptDismissCount") }
        set { UserDefaults.standard.set(newValue, forKey: "notificationPromptDismissCount") }
    }

    private var isNotificationsEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "notificationsEnabled") }
        set { UserDefaults.standard.set(newValue, forKey: "notificationsEnabled") }
    }

    private let searchUseCase: SearchAnimeUseCase
    private let toggleUseCase: ToggleFavouriteUseCase
    private let scheduleNotificationUseCase: ScheduleNotificationUseCase
    private let networkStatus: NetworkStatusProviding

    var isOffline: Bool { !networkStatus.isConnected }

    init(searchUseCase: SearchAnimeUseCase, toggleUseCase: ToggleFavouriteUseCase, scheduleNotificationUseCase: ScheduleNotificationUseCase, networkStatus: NetworkStatusProviding) {
        self.searchUseCase = searchUseCase
        self.toggleUseCase = toggleUseCase
        self.scheduleNotificationUseCase = scheduleNotificationUseCase
        self.networkStatus = networkStatus
    }

    func searchTextChanged() {
        searchTask?.cancel()

        let query = searchText.trimmingCharacters(in: .whitespaces)
        guard query.count >= 2 else {
            if query.isEmpty {
                state = .idle
                results = []
                lastSearchedQuery = ""
            }
            return
        }

        guard networkStatus.isConnected else {
            state = .error("Search requires an internet connection")
            return
        }

        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(400))
            guard !Task.isCancelled else { return }
            await performSearch(query: query)
        }
    }

    func loadNextPageIfNeeded(currentItem: Anime) {
        guard networkStatus.isConnected, hasNextPage, !isLoadingNextPage else { return }
        let thresholdIndex = results.index(results.endIndex, offsetBy: -5, limitedBy: results.startIndex) ?? results.startIndex
        guard let itemIndex = results.firstIndex(where: { $0.id == currentItem.id }),
              itemIndex >= thresholdIndex else { return }

        isLoadingNextPage = true
        Task {
            await loadNextPage()
        }
    }

    func retry() {
        guard !lastSearchedQuery.isEmpty else { return }
        guard networkStatus.isConnected else {
            state = .error("Search requires an internet connection")
            return
        }
        Task {
            await performSearch(query: lastSearchedQuery)
        }
    }

    func reloadFavouriteIDs() async {
        favouriteIDs = (try? await toggleUseCase.loadFavouriteIDs()) ?? []
    }

    func toggleFavourite(anime: Anime) async {
        print("Toggle favourite in SearchViewModel: \(anime.title)")
        let isFavourited = favouriteIDs.contains(anime.id)
        let sortOrder = results.firstIndex(where: { $0.id == anime.id }) ?? Int.max

        do {
            let newState = try await toggleUseCase.execute(
                anime: anime,
                season: anime.season,
                year: anime.seasonYear,
                sortOrder: sortOrder,
                currentlyFavourited: isFavourited
            )
            if newState {
                print("Adding anime to favourite")
                favouriteIDs.insert(anime.id)
                await handleFavourited(anime: anime, season: anime.season, year: anime.seasonYear)
            } else {
                print("Removing anime from favourite")
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
            await scheduleNotificationUseCase.scheduleForAnime(anime: anime, season: anime.season, year: anime.seasonYear)
        }
        pendingNotificationAnime = nil
        showNotificationPrompt = false
    }

    func onNotificationPromptDismiss() {
        notificationPromptDismissCount += 1
        pendingNotificationAnime = nil
        showNotificationPrompt = false
    }

    private func handleFavourited(anime: Anime, season: Season?, year: Int?) async {
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
            await scheduleNotificationUseCase.scheduleForAnime(anime: anime, season: season, year: year)
        case .denied:
            showDeniedBanner = true
        }
    }

    private func performSearch(query: String) async {
        state = .loading
        lastSearchedQuery = query
        do {
            let result = try await searchUseCase.execute(query: query, page: 1)
            guard !Task.isCancelled else { return }
            results = result.anime
            currentPage = result.currentPage
            hasNextPage = result.hasNextPage
            state = .loaded
        } catch {
            guard !Task.isCancelled else { return }
            state = .error(error.localizedDescription)
        }
    }

    private func loadNextPage() async {
        let nextPage = currentPage + 1
        do {
            let result = try await searchUseCase.execute(query: lastSearchedQuery, page: nextPage)
            let existingIDs = Set(results.map(\.id))
            let newAnime = result.anime.filter { !existingIDs.contains($0.id) }
            results.append(contentsOf: newAnime)
            currentPage = result.currentPage
            hasNextPage = result.hasNextPage
        } catch {}
        isLoadingNextPage = false
    }
}
