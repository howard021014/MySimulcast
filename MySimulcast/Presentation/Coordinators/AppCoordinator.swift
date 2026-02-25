import SwiftUI

struct AppCoordinator: View {
    var body: some View {
        TabView {
            SimulcastBrowseView()
                .tabItem { Label("Simulcast", systemImage: "tv") }
            FavouritesView()
                .tabItem { Label("Favourites", systemImage: "heart.fill") }
            Text("Search")
                .tabItem { Label("Search", systemImage: "magnifyingglass") }
        }
    }
}
