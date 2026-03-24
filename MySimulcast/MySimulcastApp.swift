import SwiftUI
import SwiftData

@main
struct MySimulcastApp: App {
    private let imageCache = ImageCache()
    private let modelContainer: ModelContainer
    private let browseViewModel: SimulcastBrowseViewModel
    private let favouritesViewModel: FavouritesViewModel
    private let searchViewModel: SearchViewModel
    private let settingsViewModel: SettingsViewModel
    private let favouriteManager: FavouriteManager

    init() {
        let container = try! ModelContainer(for: FavouriteEntry.self, CachedSeasonEntry.self)
        modelContainer = container

        let animeRepo = AnimeRepository()
        let seasonCache = SeasonCacheRepository(modelContainer: container)
        let fetchUseCase = FetchSimulcastSeasonUseCase(repository: animeRepo, cacheRepository: seasonCache)
        let favouritesRepo = FavouritesRepository(modelContainer: container)
        let toggleUseCase = ToggleFavouriteUseCase(repository: favouritesRepo)
        let networkMonitor = NetworkMonitor()

        let notificationManager = NotificationManager()
        let isNotificationsEnabled = { UserDefaults.standard.bool(forKey: "notificationsEnabled") }
        let scheduleNotificationUseCase = ScheduleNotificationUseCase(
            notificationService: notificationManager,
            isNotificationsEnabled: isNotificationsEnabled
        )
        let manageNotificationsUseCase = ManageNotificationsUseCase(
            scheduleUseCase: scheduleNotificationUseCase,
            favouritesRepository: favouritesRepo,
            notificationService: notificationManager
        )

        let favouriteManager = FavouriteManager(
            toggleUseCase: toggleUseCase,
            scheduleNotificationUseCase: scheduleNotificationUseCase,
            imageCache: imageCache
        )
        self.favouriteManager = favouriteManager

        browseViewModel = SimulcastBrowseViewModel(
            useCase: fetchUseCase,
            manageNotificationsUseCase: manageNotificationsUseCase,
            networkStatus: networkMonitor,
            favouriteManager: favouriteManager
        )

        let getUseCase = GetFavouritesUseCase(repository: favouritesRepo)
        favouritesViewModel = FavouritesViewModel(
            getUseCase: getUseCase,
            favouriteManager: favouriteManager
        )

        let searchUseCase = SearchAnimeUseCase(repository: animeRepo)
        searchViewModel = SearchViewModel(
            searchUseCase: searchUseCase,
            networkStatus: networkMonitor,
            favouriteManager: favouriteManager
        )

        settingsViewModel = SettingsViewModel(manageUseCase: manageNotificationsUseCase)

        // Backfill favourite images on launch
        let cache = imageCache
        Task {
            let allFavourites = (try? await favouritesRepo.allFavourites()) ?? []
            var urls: [URL] = []
            for fav in allFavourites {
                if let url = fav.anime.coverImageURL { urls.append(url) }
                if let url = fav.anime.thumbnailImageURL { urls.append(url) }
            }
            if !urls.isEmpty {
                await cache.storeFavouriteImages(urls: urls)
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            AppCoordinator()
                .environment(browseViewModel)
                .environment(favouritesViewModel)
                .environment(searchViewModel)
                .environment(settingsViewModel)
                .environment(favouriteManager)
                .environment(\.imageCache, imageCache)
        }
    }
}
