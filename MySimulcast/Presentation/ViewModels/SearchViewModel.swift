import Foundation
import SwiftUI

enum SearchState {
    case idle
    case loading
    case loaded
    case error(String)
}

@Observable final class SearchViewModel {
    var searchText = ""
    var state: SearchState = .idle
    var results: [Anime] = []
    var isLoadingNextPage = false

    var displayedResults: [Anime] {
        results.map { anime in
            var copy = anime
            copy.isFavourited = favouriteManager.isFavourited(id: anime.id)
            return copy
        }
    }

    private var currentPage = 1
    private var hasNextPage = false
    private var lastSearchedQuery = ""
    private var searchTask: Task<Void, Never>?

    private let searchUseCase: SearchAnimeUseCase
    private let networkStatus: NetworkStatusProviding
    let favouriteManager: FavouriteManager

    var isOffline: Bool { !networkStatus.isConnected }

    init(searchUseCase: SearchAnimeUseCase, networkStatus: NetworkStatusProviding, favouriteManager: FavouriteManager) {
        self.searchUseCase = searchUseCase
        self.networkStatus = networkStatus
        self.favouriteManager = favouriteManager
    }

    func searchTextChanged() {
        searchTask?.cancel()

        let query = searchText.trimmingCharacters(in: .whitespaces)
        guard query.count >= 2 else {
            if query.isEmpty {
                state = .idle
                results = []
                lastSearchedQuery = ""
            }
            return
        }

        guard networkStatus.isConnected else {
            state = .error("Search requires an internet connection")
            return
        }

        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(400))
            guard !Task.isCancelled else { return }
            await performSearch(query: query)
        }
    }

    func loadNextPageIfNeeded(currentItem: Anime) {
        guard networkStatus.isConnected, hasNextPage, !isLoadingNextPage else { return }
        let thresholdIndex = results.index(results.endIndex, offsetBy: -5, limitedBy: results.startIndex) ?? results.startIndex
        guard let itemIndex = results.firstIndex(where: { $0.id == currentItem.id }),
              itemIndex >= thresholdIndex else { return }

        isLoadingNextPage = true
        Task {
            await loadNextPage()
        }
    }

    func retry() {
        guard !lastSearchedQuery.isEmpty else { return }
        guard networkStatus.isConnected else {
            state = .error("Search requires an internet connection")
            return
        }
        Task {
            await performSearch(query: lastSearchedQuery)
        }
    }

    func toggleFavourite(anime: Anime) async {
        let sortOrder = results.firstIndex(where: { $0.id == anime.id }) ?? Int.max
        await favouriteManager.toggleFavourite(
            anime: anime,
            season: anime.season,
            year: anime.seasonYear,
            sortOrder: sortOrder
        )
    }

    private func performSearch(query: String) async {
        state = .loading
        lastSearchedQuery = query
        do {
            let result = try await searchUseCase.execute(query: query, page: 1)
            guard !Task.isCancelled else { return }
            results = result.anime
            currentPage = result.currentPage
            hasNextPage = result.hasNextPage
            state = .loaded
        } catch {
            guard !Task.isCancelled else { return }
            state = .error(error.localizedDescription)
        }
    }

    private func loadNextPage() async {
        let nextPage = currentPage + 1
        do {
            let result = try await searchUseCase.execute(query: lastSearchedQuery, page: nextPage)
            let existingIDs = Set(results.map(\.id))
            let newAnime = result.anime.filter { !existingIDs.contains($0.id) }
            results.append(contentsOf: newAnime)
            currentPage = result.currentPage
            hasNextPage = result.hasNextPage
        } catch {}
        isLoadingNextPage = false
    }
}
