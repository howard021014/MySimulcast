import Foundation

struct ManageNotificationsUseCase {
    private let scheduleUseCase: ScheduleNotificationUseCase
    private let favouritesRepository: FavouritesRepositoryProtocol
    private let notificationService: NotificationServiceProtocol

    init(
        scheduleUseCase: ScheduleNotificationUseCase,
        favouritesRepository: FavouritesRepositoryProtocol,
        notificationService: NotificationServiceProtocol
    ) {
        self.scheduleUseCase = scheduleUseCase
        self.favouritesRepository = favouritesRepository
        self.notificationService = notificationService
    }

    func scheduleAllFavourites() async {
        await notificationService.cancelAllNotifications()
        guard let favourites = try? await favouritesRepository.allFavourites() else { return }
        for fav in favourites {
            await scheduleUseCase.scheduleForAnime(anime: fav.anime, season: fav.season, year: fav.year)
        }
    }

    func cancelAll() async {
        await notificationService.cancelAllNotifications()
    }

    func reSyncIfNeeded(currentAnime: [Anime], season: Season, year: Int) async {
        await notificationService.cancelAllNotifications()
        guard let favourites = try? await favouritesRepository.allFavourites() else { return }
        let favouriteIDs = Set(favourites.map(\.anime.id))
        for anime in currentAnime where favouriteIDs.contains(anime.id) {
            await scheduleUseCase.scheduleForAnime(anime: anime, season: season, year: year)
        }

    }

    func authorizationStatus() async -> NotificationAuthorizationStatus {
        await notificationService.authorizationStatus()
    }

    func requestAuthorization() async throws -> Bool {
        try await notificationService.requestAuthorization()
    }
}
