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
    var state: FavouritesState = .idle {
        didSet { recomputeDerivedState() }
    }
    var selectedFilter: FavouriteFilter = .all {
        didSet { recomputeDisplayedAnime() }
    }
    var showDeniedBanner = false
    private(set) var availableFilters: [FavouriteFilter] = [.all]
    private(set) var displayedAnime: [FavouriteDisplayItem] = []

    private let getUseCase: GetFavouritesUseCase
    private let toggleUseCase: ToggleFavouriteUseCase
    private let scheduleNotificationUseCase: ScheduleNotificationUseCase

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEE MMM d"
        return f
    }()

    init(getUseCase: GetFavouritesUseCase, toggleUseCase: ToggleFavouriteUseCase, scheduleNotificationUseCase: ScheduleNotificationUseCase) {
        self.getUseCase = getUseCase
        self.toggleUseCase = toggleUseCase
        self.scheduleNotificationUseCase = scheduleNotificationUseCase
    }

    private func recomputeDerivedState() {
        guard case .loaded(let items) = state else {
            availableFilters = [.all]
            if !availableFilters.contains(selectedFilter) {
                selectedFilter = .all
            }
            recomputeDisplayedAnime()
            return
        }
        var seen = Set<FavouriteFilter>()
        var uniqueSeasons: [(Season, Int)] = []
        for item in items {
            guard let s = item.season, let y = item.year else { continue }
            let filter = FavouriteFilter.season(s, y)
            if seen.insert(filter).inserted {
                uniqueSeasons.append((s, y))
            }
        }
        if uniqueSeasons.isEmpty {
            availableFilters = [.all]
        } else {
            let seasonOrder: [Season] = [.fall, .summer, .spring, .winter]
            uniqueSeasons.sort { a, b in
                if a.1 != b.1 { return a.1 > b.1 }
                let aIdx = seasonOrder.firstIndex(of: a.0) ?? 0
                let bIdx = seasonOrder.firstIndex(of: b.0) ?? 0
                return aIdx < bIdx
            }
            availableFilters = [.all] + uniqueSeasons.map { FavouriteFilter.season($0.0, $0.1) }
        }
        if !availableFilters.contains(selectedFilter) {
            selectedFilter = .all
        } else {
            recomputeDisplayedAnime()
        }
    }

    private func recomputeDisplayedAnime() {
        displayedAnime = displayedAnime(for: selectedFilter)
    }

    func displayedAnime(for filter: FavouriteFilter) -> [FavouriteDisplayItem] {
        guard case .loaded(let items) = state else { return [] }
        let (currentSeason, currentYear) = Season.current()
        let filtered: [FavouriteAnime]
        switch filter {
        case .all:
            filtered = items.sorted { a, b in
                let aCurrent = a.season == currentSeason && a.year == currentYear
                let bCurrent = b.season == currentSeason && b.year == currentYear
                if aCurrent != bCurrent { return aCurrent }
                return a.sortOrder < b.sortOrder
            }
        case .season(let s, let y):
            filtered = items.filter { $0.season == s && $0.year == y }.sorted { $0.sortOrder < $1.sortOrder }
        }
        return filtered.map { item in
            FavouriteDisplayItem(
                anime: item.anime,
                scheduleText: scheduleText(for: item, currentSeason: currentSeason, currentYear: currentYear)
            )
        }
    }

    func load() async {
        if case .idle = state {
            state = .loading
        }
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
                sortOrder: entry.sortOrder,
                currentlyFavourited: true
            )
            await scheduleNotificationUseCase.cancelForAnime(id: anime.id)
        } catch {
            state = .loaded(items)
        }
    }

    func checkDeniedStatus() async {
        let status = await scheduleNotificationUseCase.authorizationStatus()
        showDeniedBanner = (status == .denied)
    }

    private func scheduleText(for item: FavouriteAnime, currentSeason: Season, currentYear: Int) -> String {
        guard let season = item.season, let year = item.year else {
            if let schedule = item.anime.airingSchedule {
                return "Ep \(schedule.nextEpisode) · \(Self.dateFormatter.string(from: schedule.nextAiringAt))"
            }
            return "No season info"
        }
        if season == currentSeason && year == currentYear {
            guard let schedule = item.anime.airingSchedule else { return "No schedule info" }
            return "Ep \(schedule.nextEpisode) · \(Self.dateFormatter.string(from: schedule.nextAiringAt))"
        } else {
            return "Aired in \(season.rawValue.capitalized) \(year)"
        }
    }
}
