import SwiftUI
import SwiftData

@main
struct MySimulcastApp: App {
    private let imageCache = ImageCache()
    private let modelContainer: ModelContainer
    private let browseViewModel: SimulcastBrowseViewModel
    private let favouritesViewModel: FavouritesViewModel
    private let searchViewModel: SearchViewModel

    init() {
        let container = try! ModelContainer(for: FavouriteEntry.self)
        modelContainer = container

        let animeRepo = AnimeRepository()
        let fetchUseCase = FetchSimulcastSeasonUseCase(repository: animeRepo)
        let favouritesRepo = FavouritesRepository(modelContainer: container)
        let toggleUseCase = ToggleFavouriteUseCase(repository: favouritesRepo)
        browseViewModel = SimulcastBrowseViewModel(useCase: fetchUseCase, toggleUseCase: toggleUseCase)

        let getUseCase = GetFavouritesUseCase(repository: favouritesRepo)
        favouritesViewModel = FavouritesViewModel(getUseCase: getUseCase, toggleUseCase: toggleUseCase)

        let searchUseCase = SearchAnimeUseCase(repository: animeRepo)
        searchViewModel = SearchViewModel(searchUseCase: searchUseCase, toggleUseCase: toggleUseCase)
    }

    var body: some Scene {
        WindowGroup {
            AppCoordinator()
                .environment(browseViewModel)
                .environment(favouritesViewModel)
                .environment(searchViewModel)
                .environment(\.imageCache, imageCache)
        }
    }
}
