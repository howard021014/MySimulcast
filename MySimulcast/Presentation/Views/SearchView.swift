import SwiftUI

struct SearchView: View {
    @Environment(SearchViewModel.self) private var viewModel

    var body: some View {
        @Bindable var viewModel = viewModel
        NavigationStack {
            Group {
                switch viewModel.state {
                case .idle:
                    placeholderView
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
                Task { await viewModel.reloadFavouriteIDs() }
            }
            .sheet(isPresented: Binding(
                get: { viewModel.showNotificationPrompt },
                set: { if !$0 { viewModel.onNotificationPromptDismiss() } }
            )) {
                NotificationPermissionSheet(
                    onEnable: { Task { await viewModel.onNotificationPromptEnable() } },
                    onDismiss: { viewModel.onNotificationPromptDismiss() }
                )
            }
        }
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
