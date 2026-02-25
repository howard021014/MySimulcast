import Foundation

struct FavouriteDisplayItem: Identifiable {
    let anime: Anime
    let scheduleText: String
    var id: Int { anime.id }
}

enum FavouritesState {
    case idle
    case loading
    case loaded([FavouriteAnime])
    case error(String)
}

enum FavouriteFilter: Hashable {
    case all
    case season(Season, Int)

    var label: String {
        switch self {
        case .all: return "All"
        case .season(let s, let y): return "\(s.rawValue.capitalized) \(y)"
        }
    }
}

@Observable final class FavouritesViewModel {
    var state: FavouritesState = .idle
    var selectedFilter: FavouriteFilter = .all

    private let getUseCase: GetFavouritesUseCase
    private let toggleUseCase: ToggleFavouriteUseCase

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEE MMM d"
        return f
    }()

    init(getUseCase: GetFavouritesUseCase, toggleUseCase: ToggleFavouriteUseCase) {
        self.getUseCase = getUseCase
        self.toggleUseCase = toggleUseCase
    }

    var availableFilters: [FavouriteFilter] {
        guard case .loaded(let items) = state else { return [.all] }
        var seen = Set<FavouriteFilter>()
        var uniqueSeasons: [FavouriteFilter] = []
        for item in items {
            let filter = FavouriteFilter.season(item.season, item.year)
            if seen.insert(filter).inserted {
                uniqueSeasons.append(filter)
            }
        }
        guard uniqueSeasons.count > 1 else { return [.all] }
        return [.all] + uniqueSeasons
    }

    var displayedAnime: [FavouriteDisplayItem] {
        guard case .loaded(let items) = state else { return [] }
        let (currentSeason, currentYear) = Season.current()
        let filtered: [FavouriteAnime]
        switch selectedFilter {
        case .all:
            filtered = items
        case .season(let s, let y):
            filtered = items.filter { $0.season == s && $0.year == y }
        }
        return filtered.map { item in
            FavouriteDisplayItem(
                anime: item.anime,
                scheduleText: scheduleText(for: item, currentSeason: currentSeason, currentYear: currentYear)
            )
        }
    }

    func load() async {
        state = .loading
        do {
            let items = try await getUseCase.execute()
            state = .loaded(items)
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    func toggleFavourite(anime: Anime) async {
        guard case .loaded(let items) = state else { return }
        guard let entry = items.first(where: { $0.anime.id == anime.id }) else { return }

        let updated = items.filter { $0.anime.id != anime.id }
        state = .loaded(updated)

        do {
            _ = try await toggleUseCase.execute(
                anime: anime,
                season: entry.season,
                year: entry.year,
                currentlyFavourited: true
            )
        } catch {
            state = .loaded(items)
        }
    }

    private func scheduleText(for item: FavouriteAnime, currentSeason: Season, currentYear: Int) -> String {
        if item.season == currentSeason && item.year == currentYear {
            guard let schedule = item.anime.airingSchedule else { return "No schedule info" }
            return "Ep \(schedule.nextEpisode) · \(Self.dateFormatter.string(from: schedule.nextAiringAt))"
        } else {
            return "Aired in \(item.season.rawValue.capitalized) \(item.year)"
        }
    }
}
