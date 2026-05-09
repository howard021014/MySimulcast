import SwiftUI

struct SimulcastBrowseView: View {
    @Environment(SimulcastBrowseViewModel.self) private var viewModel
    @Environment(FavouriteManager.self) private var favouriteManager
    @Environment(\.scenePhase) private var scenePhase

    private let columns = [
        GridItem(.flexible(), spacing: Spacing.gridGutter),
        GridItem(.flexible())
    ]

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                largeTitle

                seasonPillsRow

                pagedContent
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .dsBackgroundGradient()
            .toolbar(.hidden, for: .navigationBar)
            .onAppear {
                Task { await favouriteManager.loadFavouriteIDs() }
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    viewModel.refreshSeasonListIfNeeded()
                    Task { await viewModel.checkStaleAndRefresh() }
                }
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

    private var largeTitle: some View {
        Text("Simulcast")
            .font(Typography.largeTitle)
            .tracking(-0.8)
            .foregroundStyle(Color.dsText)
            .padding(.horizontal, Spacing.pageH)
            .padding(.top, 8)
            .padding(.bottom, 10)
    }

    private var seasonPillsRow: some View {
        @Bindable var vm = viewModel
        return ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
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
                .padding(.horizontal, Spacing.pageH)
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
                    cacheBanner
                }

                switch viewModel.stateForSeason(season) {
                case .idle, .loading:
                    ProgressView()
                        .tint(Color.dsAccent)
                        .frame(maxWidth: .infinity, minHeight: 200)
                case .loaded:
                    animeGrid(for: season)
                case .error(let message):
                    errorView(message: message, season: season)
                }

                if let fetchedAt = viewModel.fetchedAt(for: season) {
                    Text("Updated \(fetchedAt.formatted(date: .abbreviated, time: .shortened))")
                        .font(Typography.meta)
                        .foregroundStyle(Color.dsTextFaint)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 4)
                }
            }
            .padding(.horizontal, Spacing.pageH)
            .padding(.bottom, Spacing.tabClearance)
        }
        .task {
            await viewModel.loadSeason(season)
        }
    }

    private var cacheBanner: some View {
        Label("Content may be outdated", systemImage: "wifi.slash")
            .font(Typography.meta)
            .foregroundStyle(Color.dsTextDim)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule().fill(Color.dsCard)
            )
            .overlay(
                Capsule().strokeBorder(Color.dsSeparator, lineWidth: 1)
            )
    }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEE MMM d"
        return f
    }()

    private func animeGrid(for season: SeasonIdentifier) -> some View {
        LazyVGrid(columns: columns, spacing: Spacing.gridGutter) {
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
                .font(Typography.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.dsTextDim)

            Button {
                Task { await viewModel.retryLoadSeason(season) }
            } label: {
                Text("Try Again")
                    .font(Typography.chip)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(Color.dsAccent))
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
    }
}
