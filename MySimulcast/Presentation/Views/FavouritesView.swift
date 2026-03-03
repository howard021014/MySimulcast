import SwiftUI

struct FavouritesView: View {
    @Environment(FavouritesViewModel.self) private var viewModel

    private let columns = [GridItem(.flexible(), spacing: 16), GridItem(.flexible())]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if viewModel.showDeniedBanner {
                        deniedBanner
                    }

                    if viewModel.availableFilters.count > 1 {
                        filterPillsRow
                    }

                    switch viewModel.state {
                    case .idle:
                        EmptyView()
                    case .loading:
                        ProgressView()
                            .frame(maxWidth: .infinity, minHeight: 200)
                    case .loaded:
                        if viewModel.displayedAnime.isEmpty {
                            emptyState
                        } else {
                            animeGrid
                        }
                    case .error(let message):
                        Text(message)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, minHeight: 200)
                    }
                }
                .padding(.horizontal)
            }
            .navigationTitle("Favourites")
            .task {
                await viewModel.load()
                await viewModel.checkDeniedStatus()
            }
        }
    }

    private var deniedBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "bell.slash")
                .foregroundStyle(.secondary)
            Text("Notifications are disabled.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Button("Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .font(.subheadline)
            .buttonStyle(.bordered)
        }
        .padding(12)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var filterPillsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(viewModel.availableFilters, id: \.self) { filter in
                    FilterPillView(
                        label: filter.label,
                        isSelected: viewModel.selectedFilter == filter
                    ) {
                        viewModel.selectedFilter = filter
                    }
                }
            }
        }
    }

    private var animeGrid: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(viewModel.displayedAnime) { item in
                AnimeCardView(anime: item.anime, scheduleText: item.scheduleText) {
                    Task { await viewModel.toggleFavourite(anime: item.anime) }
                }
            }
        }
    }

    private var emptyState: some View {
        Text("No favourites yet. Tap \u{2665} on any show to add one.")
            .multilineTextAlignment(.center)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, minHeight: 200)
    }
}

private struct FilterPillView: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.accentColor : Color(.systemGray5))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
