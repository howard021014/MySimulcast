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

        browseViewModel = SimulcastBrowseViewModel(
            useCase: fetchUseCase,
            toggleUseCase: toggleUseCase,
            scheduleNotificationUseCase: scheduleNotificationUseCase,
            manageNotificationsUseCase: manageNotificationsUseCase,
            networkStatus: networkMonitor
        )

        let getUseCase = GetFavouritesUseCase(repository: favouritesRepo)
        favouritesViewModel = FavouritesViewModel(
            getUseCase: getUseCase,
            toggleUseCase: toggleUseCase,
            scheduleNotificationUseCase: scheduleNotificationUseCase
        )

        let searchUseCase = SearchAnimeUseCase(repository: animeRepo)
        searchViewModel = SearchViewModel(
            searchUseCase: searchUseCase,
            toggleUseCase: toggleUseCase,
            scheduleNotificationUseCase: scheduleNotificationUseCase,
            networkStatus: networkMonitor
        )

        settingsViewModel = SettingsViewModel(manageUseCase: manageNotificationsUseCase)
    }

    var body: some Scene {
        WindowGroup {
            AppCoordinator()
                .environment(browseViewModel)
                .environment(favouritesViewModel)
                .environment(searchViewModel)
                .environment(settingsViewModel)
                .environment(\.imageCache, imageCache)
        }
    }
}
