import SwiftUI

struct FavouritesView: View {
    @Environment(FavouritesViewModel.self) private var viewModel
    @Environment(FavouriteManager.self) private var favouriteManager

    private let columns = [
        GridItem(.flexible(), spacing: Spacing.gridGutter),
        GridItem(.flexible())
    ]

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                largeTitle

                if favouriteManager.showDeniedBanner {
                    deniedBanner
                        .padding(.horizontal, Spacing.pageH)
                }

                if viewModel.availableFilters.count > 1 {
                    filterPillsRow
                }

                content
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .dsBackgroundGradient()
            .toolbar(.hidden, for: .navigationBar)
            .onAppear {
                Task {
                    await viewModel.load()
                    await favouriteManager.checkDeniedStatus()
                }
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle:
            EmptyView()
        case .loading:
            ProgressView()
                .tint(Color.dsAccent)
                .frame(maxWidth: .infinity, minHeight: 200)
        case .loaded(let items):
            if items.isEmpty {
                EmptyStateView(
                    systemImage: "heart",
                    title: "No favourites yet",
                    message: "Tap the heart on any show to start tracking it here."
                )
            } else {
                pagedContent
            }
        case .error(let message):
            Text(message)
                .font(Typography.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.dsTextDim)
                .frame(maxWidth: .infinity, minHeight: 200)
        }
    }

    private var largeTitle: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("Favourites")
                .font(Typography.largeTitle)
                .tracking(-0.8)
                .foregroundStyle(Color.dsText)
            Spacer()
            if case .loaded(let items) = viewModel.state, !items.isEmpty {
                Text("\(items.count) \(items.count == 1 ? "show" : "shows")")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.dsTextDim)
            }
        }
        .padding(.horizontal, Spacing.pageH)
        .padding(.top, 8)
        .padding(.bottom, 10)
    }

    private var deniedBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "bell.slash")
                .foregroundStyle(Color.dsTextDim)
            Text("Notifications are disabled.")
                .font(Typography.meta)
                .foregroundStyle(Color.dsTextDim)
            Spacer()
            Button("Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(Color.dsAccent)
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: Radii.group, style: .continuous)
                .fill(Color.dsCard)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Radii.group, style: .continuous)
                .strokeBorder(Color.dsSeparator, lineWidth: 1)
        )
    }

    private var filterPillsRow: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(viewModel.availableFilters, id: \.self) { filter in
                        FilterPillView(
                            label: filter.label,
                            isSelected: viewModel.selectedFilter == filter
                        ) {
                            viewModel.selectedFilter = filter
                        }
                        .id(filter)
                    }
                }
                .padding(.horizontal, Spacing.pageH)
            }
            .onChange(of: viewModel.selectedFilter) { _, newValue in
                withAnimation {
                    proxy.scrollTo(newValue, anchor: .center)
                }
            }
        }
    }

    private var pagedContent: some View {
        @Bindable var vm = viewModel
        return TabView(selection: $vm.selectedFilter) {
            ForEach(viewModel.availableFilters, id: \.self) { filter in
                pageForFilter(filter)
                    .tag(filter)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
    }

    private func pageForFilter(_ filter: FavouriteFilter) -> some View {
        let items = viewModel.displayedAnime(for: filter)
        return Group {
            if items.isEmpty {
                Text("Nothing in this season yet.")
                    .font(Typography.body)
                    .foregroundStyle(Color.dsTextDim)
                    .frame(maxWidth: .infinity, minHeight: 200)
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVGrid(columns: columns, spacing: Spacing.gridGutter) {
                        ForEach(items) { item in
                            AnimeCardView(anime: item.anime, scheduleText: item.scheduleText) {
                                Task { await viewModel.toggleFavourite(anime: item.anime) }
                            }
                        }
                    }
                    .padding(.horizontal, Spacing.pageH)
                    .padding(.bottom, Spacing.tabClearance)
                }
            }
        }
    }
}
