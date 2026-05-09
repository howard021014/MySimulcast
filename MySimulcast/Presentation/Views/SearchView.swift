import SwiftUI

struct SearchView: View {
    @Environment(SearchViewModel.self) private var viewModel
    @Environment(FavouriteManager.self) private var favouriteManager

    @FocusState private var fieldFocused: Bool

    private var isActive: Bool {
        fieldFocused || !viewModel.searchText.isEmpty
    }

    var body: some View {
        @Bindable var vm = viewModel
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                if !isActive {
                    largeTitle
                }

                searchBar(text: $vm.searchText)

                content
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .dsBackgroundGradient()
            .toolbar(.hidden, for: .navigationBar)
            .onChange(of: viewModel.searchText) {
                viewModel.searchTextChanged()
            }
            .onAppear {
                Task { await favouriteManager.loadFavouriteIDs() }
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
        Text("Search")
            .font(Typography.largeTitle)
            .tracking(-0.8)
            .foregroundStyle(Color.dsText)
            .padding(.horizontal, Spacing.pageH)
            .padding(.top, 8)
            .padding(.bottom, 4)
    }

    private func searchBar(text: Binding<String>) -> some View {
        HStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(isActive ? Color.dsAccent : Color.dsTextFaint)

                TextField("",
                          text: text,
                          prompt: Text("Search anime by title").foregroundStyle(Color.dsTextFaint))
                    .font(Typography.rowTitle)
                    .foregroundStyle(Color.dsText)
                    .textInputAutocapitalization(.never)
                    .submitLabel(.search)
                    .focused($fieldFocused)

                if !text.wrappedValue.isEmpty {
                    Button {
                        text.wrappedValue = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(Color.dsTextFaint)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .frame(height: 38)
            .background(
                RoundedRectangle(cornerRadius: Radii.field, style: .continuous)
                    .fill(Color.dsFieldBg)
            )

            if isActive {
                Button {
                    fieldFocused = false
                    text.wrappedValue = ""
                } label: {
                    Text("Cancel")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color.dsAccent)
                }
                .buttonStyle(.plain)
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .padding(.horizontal, Spacing.pageH)
        .animation(.easeInOut(duration: 0.18), value: isActive)
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle:
            if viewModel.isOffline {
                offlinePlaceholderView
            } else if isActive {
                Spacer()
            } else {
                EmptyStateView(
                    systemImage: "magnifyingglass",
                    title: "Find your next show",
                    message: "Search the entire AniList catalog by title."
                )
                .padding(.bottom, Spacing.tabClearance)
            }
        case .loading:
            ProgressView()
                .tint(Color.dsAccent)
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

    private var offlinePlaceholderView: some View {
        EmptyStateView(
            systemImage: "wifi.slash",
            title: "You're offline",
            message: "Search requires an internet connection."
        )
        .padding(.bottom, Spacing.tabClearance)
    }

    private var emptyResultsView: some View {
        EmptyStateView(
            systemImage: "text.magnifyingglass",
            title: "No results found",
            message: "Try a different title or check the spelling."
        )
        .padding(.bottom, Spacing.tabClearance)
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 38))
                .foregroundStyle(Color.dsTextDim)
            Text(message)
                .font(Typography.body)
                .foregroundStyle(Color.dsTextDim)
                .multilineTextAlignment(.center)
            Button {
                viewModel.retry()
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var resultsList: some View {
        ScrollView {
            VStack(spacing: 0) {
                Text("\(viewModel.displayedResults.count) RESULTS")
                    .font(Typography.groupHeader)
                    .tracking(0.8)
                    .foregroundStyle(Color.dsTextDim)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 8)
                    .padding(.bottom, 4)

                ForEach(Array(viewModel.displayedResults.enumerated()), id: \.element.id) { index, anime in
                    SearchResultRow(anime: anime) {
                        Task { await viewModel.toggleFavourite(anime: anime) }
                    }
                    .onAppear {
                        viewModel.loadNextPageIfNeeded(currentItem: anime)
                    }

                    if index < viewModel.displayedResults.count - 1 {
                        Rectangle()
                            .fill(Color.dsSeparator)
                            .frame(height: 0.5)
                    }
                }

                if viewModel.isLoadingNextPage {
                    ProgressView()
                        .tint(Color.dsAccent)
                        .padding(.vertical, 16)
                }
            }
            .padding(.horizontal, Spacing.pageH)
            .padding(.bottom, Spacing.tabClearance)
        }
        .scrollDismissesKeyboard(.interactively)
    }
}
