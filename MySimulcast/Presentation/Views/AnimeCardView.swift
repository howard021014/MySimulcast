import SwiftUI

struct AnimeCardView: View {
    let anime: Anime
    let onToggleFavourite: () -> Void

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEE MMM d"
        return f
    }()

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .topTrailing) {
                CachedAsyncImage(url: anime.coverImageURL) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Rectangle()
                        .fill(Color(.systemGray5))
                }
                .aspectRatio(1, contentMode: .fit)

                Button(action: onToggleFavourite) {
                    Image(systemName: anime.isFavourited ? "heart.fill" : "heart")
                        .foregroundStyle(.pink)
                        .padding(8)
                }
                .buttonStyle(.plain)
            }
            .clipped()

            VStack(alignment: .leading, spacing: 4) {
                Text(anime.title)
                    .font(.subheadline)
                    .bold()
                    .lineLimit(2)

                if let schedule = anime.airingSchedule {
                    Label("Next Episode", systemImage: "calendar")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Label(airingString(for: schedule), systemImage: "clock")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func airingString(for schedule: AiringSchedule) -> String {
        "Ep \(schedule.nextEpisode) · \(Self.dateFormatter.string(from: schedule.nextAiringAt))"
    }
}
