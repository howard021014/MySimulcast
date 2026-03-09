import SwiftUI

struct AnimeDetailSheet: View {
    let anime: Anime

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    CachedAsyncImage(url: anime.coverImageURL) { image in
                        image
                            .resizable()
                            .scaledToFit()
                    } placeholder: {
                        Rectangle()
                            .fill(Color(.systemGray5))
                            .aspectRatio(2/3, contentMode: .fit)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    Text(anime.title)
                        .font(.title2)
                        .bold()

                    if let season = anime.season, let year = anime.seasonYear {
                        Text("\(season.rawValue.capitalized) \(String(year))")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    if let schedule = anime.airingSchedule {
                        Label(
                            "Episode \(schedule.nextEpisode) \(Self.airingText(schedule))",
                            systemImage: "clock"
                        )
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    }

                    Text(anime.description ?? "No description available.")
                        .font(.body)
                }
                .padding()
            }
            .navigationTitle(anime.title)
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private static func airingText(_ schedule: AiringSchedule) -> String {
        if schedule.nextAiringAt > Date.now {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .short
            return formatter.localizedString(for: schedule.nextAiringAt, relativeTo: .now)
        } else {
            return "aired"
        }
    }
}
