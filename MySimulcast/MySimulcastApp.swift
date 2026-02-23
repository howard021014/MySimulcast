import SwiftUI

@main
struct MySimulcastApp: App {
    private let imageCache = ImageCache()
    private let viewModel: SimulcastBrowseViewModel = {
        let repo = AnimeRepository()
        let useCase = FetchSimulcastSeasonUseCase(repository: repo)
        return SimulcastBrowseViewModel(useCase: useCase)
    }()

    var body: some Scene {
        WindowGroup {
            SimulcastBrowseView()
                .environment(viewModel)
                .environment(\.imageCache, imageCache)
        }
    }
}
