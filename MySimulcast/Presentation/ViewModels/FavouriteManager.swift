import Foundation

@Observable final class FavouriteManager {
    private(set) var favouriteIDs: Set<Int> = []
    var showNotificationPrompt = false
    var showDeniedBanner = false

    private var pendingNotificationAnime: Anime?
    private var pendingSeason: Season?
    private var pendingYear: Int?

    private var notificationPromptDismissCount: Int {
        get { UserDefaults.standard.integer(forKey: "notificationPromptDismissCount") }
        set { UserDefaults.standard.set(newValue, forKey: "notificationPromptDismissCount") }
    }

    private var isNotificationsEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "notificationsEnabled") }
        set { UserDefaults.standard.set(newValue, forKey: "notificationsEnabled") }
    }

    private let toggleUseCase: ToggleFavouriteUseCase
    private let scheduleNotificationUseCase: ScheduleNotificationUseCase
    private let imageCache: ImageCache

    init(
        toggleUseCase: ToggleFavouriteUseCase,
        scheduleNotificationUseCase: ScheduleNotificationUseCase,
        imageCache: ImageCache
    ) {
        self.toggleUseCase = toggleUseCase
        self.scheduleNotificationUseCase = scheduleNotificationUseCase
        self.imageCache = imageCache
    }

    func isFavourited(id: Int) -> Bool {
        favouriteIDs.contains(id)
    }

    func loadFavouriteIDs() async {
        favouriteIDs = (try? await toggleUseCase.loadFavouriteIDs()) ?? favouriteIDs
    }

    func toggleFavourite(anime: Anime, season: Season?, year: Int?, sortOrder: Int) async {
        let currentlyFavourited = favouriteIDs.contains(anime.id)
        do {
            let newState = try await toggleUseCase.execute(
                anime: anime,
                season: season,
                year: year,
                sortOrder: sortOrder,
                currentlyFavourited: currentlyFavourited
            )
            if newState {
                favouriteIDs.insert(anime.id)
                let urls = [anime.coverImageURL, anime.thumbnailImageURL].compactMap { $0 }
                await imageCache.storeFavouriteImages(urls: urls)
                await handleFavourited(anime: anime, season: season, year: year)
            } else {
                favouriteIDs.remove(anime.id)
                let urls = [anime.coverImageURL, anime.thumbnailImageURL].compactMap { $0 }
                imageCache.removeFavouriteImages(urls: urls)
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
                anime: anime, season: pendingSeason, year: pendingYear
            )
        }
        pendingNotificationAnime = nil
        pendingSeason = nil
        pendingYear = nil
        showNotificationPrompt = false
    }

    func onNotificationPromptDismiss() {
        notificationPromptDismissCount += 1
        pendingNotificationAnime = nil
        pendingSeason = nil
        pendingYear = nil
        showNotificationPrompt = false
    }

    func checkDeniedStatus() async {
        let status = await scheduleNotificationUseCase.authorizationStatus()
        showDeniedBanner = (status == .denied)
    }

    private func handleFavourited(anime: Anime, season: Season?, year: Int?) async {
        guard anime.airingSchedule != nil else { return }

        let status = await scheduleNotificationUseCase.authorizationStatus()
        switch status {
        case .notDetermined:
            if notificationPromptDismissCount < 2 {
                pendingNotificationAnime = anime
                pendingSeason = season
                pendingYear = year
                showNotificationPrompt = true
            }
        case .authorized, .provisional:
            isNotificationsEnabled = true
            await scheduleNotificationUseCase.scheduleForAnime(
                anime: anime, season: season, year: year
            )
        case .denied:
            showDeniedBanner = true
        }
    }
}
