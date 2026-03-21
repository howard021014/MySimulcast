import SwiftUI

struct SimulcastBrowseView: View {
    @Environment(SimulcastBrowseViewModel.self) private var viewModel
    @Environment(\.scenePhase) private var scenePhase

    private let columns = [GridItem(.flexible(), spacing: 16), GridItem(.flexible())]

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                seasonPillsRow

                pagedContent
            }
            .navigationTitle("Simulcast")
            .onAppear {
                Task { await viewModel.refreshFavouriteIDs() }
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    viewModel.refreshSeasonListIfNeeded()
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
        @Bindable var vm = viewModel
        return ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(vm.seasons) { season in
                        FilterPillView(
                            label: season.label,
                            isSelected: vm.selectedSeason == season
                        ) {
                            vm.selectedSeason = season
                        }
                        .id(season)
                    }
                }
                .padding(.horizontal)
            }
            .onChange(of: vm.selectedSeason) { _, newValue in
                withAnimation {
                    proxy.scrollTo(newValue, anchor: .center)
                }
            }
        }
    }

    private var pagedContent: some View {
        @Bindable var vm = viewModel
        return TabView(selection: $vm.selectedSeason) {
            ForEach(vm.seasons) { season in
                seasonPage(for: season)
                    .tag(season)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
    }

    private func seasonPage(for season: SeasonIdentifier) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                if viewModel.isShowingCacheBanner(for: season) {
                    Label("Content may be outdated", systemImage: "wifi.slash")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
                }

                switch viewModel.stateForSeason(season) {
                case .idle:
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: 200)
                case .loading:
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: 200)
                case .loaded:
                    animeGrid(for: season)
                case .error(let message):
                    errorView(message: message, season: season)
                }

                if let fetchedAt = viewModel.fetchedAt(for: season) {
                    Text("Updated \(fetchedAt.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.horizontal)
        }
        .task {
            await viewModel.loadSeason(season)
        }
    }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEE MMM d"
        return f
    }()

    private func animeGrid(for season: SeasonIdentifier) -> some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(viewModel.anime(for: season)) { anime in
                AnimeCardView(anime: anime, scheduleText: scheduleText(for: anime)) {
                    Task { await viewModel.toggleFavourite(anime: anime) }
                }
            }
        }
    }

    private func scheduleText(for anime: Anime) -> String {
        guard let schedule = anime.airingSchedule else { return "No schedule info" }
        return "Ep \(schedule.nextEpisode) · \(Self.dateFormatter.string(from: schedule.nextAiringAt))"
    }

    private func errorView(message: String, season: SeasonIdentifier) -> some View {
        VStack(spacing: 12) {
            Text(message)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            Button("Try Again") {
                Task {
                    await viewModel.retryLoadSeason(season)
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
    }
}
