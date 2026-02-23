import SwiftUI
import SwiftData

@main
struct MySimulcastApp: App {
    private let imageCache = ImageCache()
    private let modelContainer: ModelContainer
    private let viewModel: SimulcastBrowseViewModel

    init() {
        let container = try! ModelContainer(for: FavouriteEntry.self)
        modelContainer = container

        let animeRepo = AnimeRepository()
        let fetchUseCase = FetchSimulcastSeasonUseCase(repository: animeRepo)
        let favouritesRepo = FavouritesRepository(modelContainer: container)
        let toggleUseCase = ToggleFavouriteUseCase(repository: favouritesRepo)
        viewModel = SimulcastBrowseViewModel(useCase: fetchUseCase, toggleUseCase: toggleUseCase)
    }

    var body: some Scene {
        WindowGroup {
            SimulcastBrowseView()
                .environment(viewModel)
                .environment(\.imageCache, imageCache)
        }
    }
}
