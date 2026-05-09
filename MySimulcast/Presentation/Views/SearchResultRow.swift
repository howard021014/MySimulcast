import SwiftUI

struct SearchResultRow: View {
    let anime: Anime
    let onToggleFavourite: () -> Void

    private var subtitle: String {
        var parts: [String] = ["TV"]
        if let episodes = anime.episodes {
            parts.append("\(episodes) episodes")
        }
        if let year = anime.seasonYear {
            parts.append(String(year))
        }
        return parts.joined(separator: " · ")
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            CachedAsyncImage(url: anime.thumbnailImageURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color.dsImagePlaceholder)
            }
            .frame(width: 50, height: 70)
            .clipShape(RoundedRectangle(cornerRadius: Radii.thumb, style: .continuous))
            .shadow(color: .black.opacity(0.4), radius: 4, x: 0, y: 2)

            VStack(alignment: .leading, spacing: 3) {
                Text(anime.title)
                    .font(Typography.rowTitle)
                    .tracking(-0.1)
                    .foregroundStyle(Color.dsText)
                    .lineLimit(2)

                Text(subtitle)
                    .font(Typography.meta)
                    .foregroundStyle(Color.dsTextDim)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 16) {
                Button {
                    onToggleFavourite()
                } label: {
                    Image(systemName: anime.isFavourited ? "heart.fill" : "heart")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(anime.isFavourited ? Color.dsAccent : Color.dsTextFaint)
                }
                .buttonStyle(.plain)

                Image(systemName: "ellipsis")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.dsTextFaint)
                    .rotationEffect(.degrees(90))
            }
            .padding(.top, 4)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 4)
    }
}
