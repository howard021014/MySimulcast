import SwiftUI

struct SearchView: View {
    @Environment(SearchViewModel.self) private var viewModel
    @Environment(FavouriteManager.self) private var favouriteManager

    var body: some View {
        @Bindable var viewModel = viewModel
        NavigationStack {
            Group {
                switch viewModel.state {
                case .idle:
                    if viewModel.isOffline {
                        offlinePlaceholderView
                    } else {
                        placeholderView
                    }
                case .loading:
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                case .loaded:
                    if viewModel.displayedResults.isEmpty {
                        emptyResultsView
                    } else {
                        resultsList
                    }
                case .error(let message):
                    errorView(message: message)
                }
            }
            .navigationTitle("Search")
            .searchable(text: $viewModel.searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search anime by title")
            .onChange(of: viewModel.searchText) {
                viewModel.searchTextChanged()
            }
            .onAppear {
                Task { await favouriteManager.loadFavouriteIDs() }
            }
            .sheet(isPresented: Binding(
                get: { favouriteManager.showNotificationPrompt },
                set: { if !$0 { favouriteManager.onNotificationPromptDismiss() } }
            )) {
                NotificationPermissionSheet(
                    onEnable: { Task { await favouriteManager.onNotificationPromptEnable() } },
                    onDismiss: { favouriteManager.onNotificationPromptDismiss() }
                )
            }
        }
    }

    private var offlinePlaceholderView: some View {
        VStack(spacing: 12) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("Search requires an internet connection")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var placeholderView: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("Search for anime by title")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyResultsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("No results found")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text(message)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Retry") {
                viewModel.retry()
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var resultsList: some View {
        List(viewModel.displayedResults) { anime in
            SearchResultRow(anime: anime) {
                Task { await viewModel.toggleFavourite(anime: anime) }
            }
            .onAppear {
                viewModel.loadNextPageIfNeeded(currentItem: anime)
            }
        }
        .listStyle(.plain)
        .scrollDismissesKeyboard(.interactively)
    }
}
