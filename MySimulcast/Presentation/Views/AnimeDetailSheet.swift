import SwiftUI

struct AnimeDetailSheet: View {
    let anime: Anime
    @Environment(\.dismiss) private var dismiss
    @Environment(FavouriteManager.self) private var favouriteManager

    private static let countdownDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEEE"
        return f
    }()

    private var isFavourited: Bool {
        favouriteManager.isFavourited(id: anime.id)
    }

    private var eyebrowParts: [String] {
        var parts: [String] = []
        if let season = anime.season, let year = anime.seasonYear {
            parts.append("\(season.rawValue.capitalized) \(year)")
        }
        if let genres = anime.genres {
            parts.append(contentsOf: genres.prefix(3))
        }
        return parts
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color.dsBg
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    hero
                    contentPanel
                        .offset(y: -36)
                }
            }
            .ignoresSafeArea(edges: .top)

            floatingTopBar
        }
        .preferredColorScheme(.dark)
    }

    private var hero: some View {
        ZStack(alignment: .bottom) {
            CachedAsyncImage(url: anime.coverImageURL) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                Rectangle()
                    .fill(Color.dsImagePlaceholder)
            }
            .frame(height: 420)
            .frame(maxWidth: .infinity)
            .clipped()

            LinearGradient(
                colors: [.clear, Color.dsBg.opacity(0.6), Color.dsBg],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 140)
        }
        .frame(height: 420)
    }

    private var floatingTopBar: some View {
        HStack {
            iconBubble(systemName: "xmark") {
                dismiss()
            }
            Spacer()
            Button {
                Task {
                    await favouriteManager.toggleFavourite(
                        anime: anime,
                        season: anime.season,
                        year: anime.seasonYear,
                        sortOrder: Int.max
                    )
                }
            } label: {
                Image(systemName: isFavourited ? "heart.fill" : "heart")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(isFavourited ? Color.dsAccent : Color.dsText)
                    .frame(width: 32, height: 32)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Spacing.pageH)
        .padding(.top, 8)
    }

    private func iconBubble(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.dsText)
                .frame(width: 32, height: 32)
                .background(.ultraThinMaterial, in: Circle())
        }
        .buttonStyle(.plain)
    }

    private var contentPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            if !eyebrowParts.isEmpty {
                Text(eyebrowParts.joined(separator: " · "))
                    .font(Typography.eyebrow)
                    .tracking(1.5)
                    .textCase(.uppercase)
                    .foregroundStyle(Color.dsAccent)
            }

            Text(anime.title)
                .font(Typography.detailTitle)
                .tracking(-0.5)
                .foregroundStyle(Color.dsText)
                .fixedSize(horizontal: false, vertical: true)

            if anime.airingSchedule != nil {
                countdownCard
            }

            statsRow

            synopsis
        }
        .padding(.horizontal, Spacing.pageHWide)
        .padding(.bottom, 32)
    }

    @ViewBuilder
    private var countdownCard: some View {
        if let schedule = anime.airingSchedule {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.dsAccent)
                        .frame(width: 44, height: 44)
                    Image(systemName: "clock")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Next episode")
                        .font(Typography.meta)
                        .foregroundStyle(Color.dsTextDim)
                    Text(nextEpisodeText(schedule))
                        .font(Typography.sectionHeader)
                        .foregroundStyle(Color.dsText)
                }
                Spacer()
                Text(countdownText(schedule))
                    .font(Typography.numeric)
                    .tracking(-0.5)
                    .foregroundStyle(Color.dsAccent)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: Radii.group, style: .continuous)
                    .fill(Color.dsAccentSoft)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Radii.group, style: .continuous)
                    .strokeBorder(Color.dsAccent, lineWidth: 1)
            )
        }
    }

    private var statsRow: some View {
        let tiles: [(label: String, value: String)] = {
            var items: [(String, String)] = []
            if let studios = anime.studios, let first = studios.first {
                items.append(("STUDIO", first))
            }
            if let episodes = anime.episodes {
                items.append(("EPISODES", "\(episodes)"))
            }
            if let schedule = anime.airingSchedule {
                items.append(("AIRS", Self.countdownDateFormatter.string(from: schedule.nextAiringAt)))
            }
            return items
        }()

        return Group {
            if !tiles.isEmpty {
                HStack(spacing: 10) {
                    ForEach(tiles, id: \.label) { tile in
                        statTile(label: tile.label, value: tile.value)
                    }
                }
            }
        }
    }

    private func statTile(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .tracking(0.8)
                .foregroundStyle(Color.dsTextDim)
            Text(value)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.dsText)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: Radii.group, style: .continuous)
                .fill(Color.dsCard)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Radii.group, style: .continuous)
                .strokeBorder(Color.dsCardInsetStroke, lineWidth: 1)
        )
    }

    private var synopsis: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Synopsis")
                .font(Typography.sectionHeader)
                .tracking(-0.2)
                .foregroundStyle(Color.dsText)
            Text(synopsisText)
                .font(Typography.body)
                .foregroundStyle(Color.dsTextDim)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var synopsisText: String {
        guard let raw = anime.description, !raw.isEmpty else {
            return "No description available."
        }
        return raw
            .replacingOccurrences(of: "<br>", with: "\n")
            .replacingOccurrences(of: "<br/>", with: "\n")
            .replacingOccurrences(of: "<br />", with: "\n")
            .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func nextEpisodeText(_ schedule: AiringSchedule) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        let when: String
        if schedule.nextAiringAt > .now {
            when = formatter.localizedString(for: schedule.nextAiringAt, relativeTo: .now)
        } else {
            when = "already aired"
        }
        return "Episode \(schedule.nextEpisode) \(when)"
    }

    private func countdownText(_ schedule: AiringSchedule) -> String {
        let interval = schedule.nextAiringAt.timeIntervalSince(.now)
        guard interval > 0 else { return "—" }
        let days = Int(interval / 86_400)
        let hours = Int((interval.truncatingRemainder(dividingBy: 86_400)) / 3_600)
        if days > 0 {
            return "\(days)d \(hours)h"
        }
        let minutes = Int((interval.truncatingRemainder(dividingBy: 3_600)) / 60)
        return "\(hours)h \(minutes)m"
    }

}
