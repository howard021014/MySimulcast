import SwiftUI

struct SimulcastBrowseView: View {
    @Environment(SimulcastBrowseViewModel.self) private var viewModel
    @Environment(\.scenePhase) private var scenePhase

    private let columns = [GridItem(.flexible(), spacing: 16), GridItem(.flexible())]

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

                    if let fetchedAt = viewModel.fetchedAt {
                        Text("Updated \(fetchedAt.formatted(date: .abbreviated, time: .shortened))")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.horizontal)
            }
            .navigationTitle("Simulcast")
            .task {
                await viewModel.loadSeason()
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    Task { await viewModel.checkStaleAndRefresh() }
                }
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

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEE MMM d"
        return f
    }()

    private var animeGrid: some View {
        VStack(alignment: .leading, spacing: 8) {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(viewModel.anime) { anime in
                    AnimeCardView(anime: anime, scheduleText: scheduleText(for: anime)) {
                        Task { await viewModel.toggleFavourite(anime: anime) }
                    }
                }
            }
        }
    }

    private func scheduleText(for anime: Anime) -> String {
        guard let schedule = anime.airingSchedule else { return "No schedule info" }
        return "Ep \(schedule.nextEpisode) · \(Self.dateFormatter.string(from: schedule.nextAiringAt))"
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
