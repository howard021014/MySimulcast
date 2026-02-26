import SwiftUI

struct SearchResultRow: View {
    let anime: Anime
    let onToggleFavourite: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            CachedAsyncImage(url: anime.thumbnailImageURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color(.systemGray5))
            }
            .frame(width: 60, height: 85)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            Text(anime.title)
                .font(.body)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 16) {
                Button {
                    onToggleFavourite()
                } label: {
                    Image(systemName: anime.isFavourited ? "heart.fill" : "heart")
                        .foregroundStyle(anime.isFavourited ? .pink : .secondary)
                }
                .buttonStyle(.plain)

                Button {} label: {
                    Image(systemName: "ellipsis")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
    }
}
