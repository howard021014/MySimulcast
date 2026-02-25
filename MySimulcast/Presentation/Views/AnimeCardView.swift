import SwiftUI

struct AnimeCardView: View {
    let anime: Anime
    let scheduleText: String
    let onToggleFavourite: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Color.clear
                .aspectRatio(2/3, contentMode: .fit)
                .overlay {
                    CachedAsyncImage(url: anime.coverImageURL) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        Rectangle()
                            .fill(Color(.systemGray5))
                    }
                }
                .clipped()
                .overlay(alignment: .topTrailing) {
                    Button(action: onToggleFavourite) {
                        Image(systemName: anime.isFavourited ? "heart.fill" : "heart")
                            .foregroundStyle(.pink)
                            .padding(12)
                    }
                    .buttonStyle(.plain)
                    .contentShape(Rectangle())
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(anime.title)
                    .font(.subheadline)
                    .bold()
                    .lineLimit(2)

                Label(scheduleText, systemImage: "clock")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12).padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer(minLength: 0)
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
