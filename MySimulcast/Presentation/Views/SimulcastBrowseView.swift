import SwiftUI

struct SimulcastBrowseView: View {
    @Environment(SimulcastBrowseViewModel.self) private var viewModel

    private let columns = [GridItem(.flexible(), spacing: 8), GridItem(.flexible())]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    seasonPillsRow

                    switch viewModel.browseState {
                    case .idle:
                        EmptyView()
                    case .loading:
                        ProgressView()
                            .frame(maxWidth: .infinity, minHeight: 200)
                    case .loaded:
                        animeGrid
                    case .error(let message):
                        errorView(message: message)
                    }
                }
                .padding(.horizontal)
            }
            .navigationTitle("Simulcast")
            .refreshable {
                await viewModel.refresh()
            }
            .task {
                await viewModel.loadSeason()
            }
        }
    }

    private var seasonPillsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                SeasonPillView(
                    season: viewModel.currentSeason,
                    year: viewModel.currentYear,
                    isSelected: true
                )
            }
        }
    }

    private var animeGrid: some View {
        VStack(alignment: .leading, spacing: 8) {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(viewModel.anime) { anime in
                    AnimeCardView(anime: anime)
                }
            }

            if let fetchedAt = viewModel.fetchedAt {
                Text("Updated \(fetchedAt.formatted(.relative(presentation: .named)))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 4)
            }
        }
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 12) {
            Text(message)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            Button("Try Again") {
                Task {
                    await viewModel.loadSeason()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
    }
}

private struct SeasonPillView: View {
    let season: Season
    let year: Int
    let isSelected: Bool

    private var label: String {
        "\(season.rawValue.capitalized) \(year)"
    }

    var body: some View {
        Text(label)
            .font(.subheadline)
            .fontWeight(isSelected ? .semibold : .regular)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? Color.accentColor : Color(.systemGray5))
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(Capsule())
    }
}
