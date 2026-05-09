import SwiftUI

struct AnimeCardView: View {
    let anime: Anime
    let scheduleText: String
    let onToggleFavourite: () -> Void

    @State private var showDetailSheet = false

    var body: some View {
        Button {
            showDetailSheet = true
        } label: {
            VStack(spacing: 0) {
                cover
                meta
            }
            .frame(maxHeight: .infinity, alignment: .top)
            .background(
                RoundedRectangle(cornerRadius: Radii.card, style: .continuous)
                    .fill(Color.dsCard)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Radii.card, style: .continuous)
                    .strokeBorder(Color.dsCardInsetStroke, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: Radii.card, style: .continuous))
            .dsCardShadow()
        }
        .buttonStyle(PressableCardStyle())
        .sheet(isPresented: $showDetailSheet) {
            AnimeDetailSheet(anime: anime)
        }
    }

    private var cover: some View {
        Color.clear
            .aspectRatio(3/4, contentMode: .fit)
            .overlay {
                CachedAsyncImage(url: anime.coverImageURL) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Rectangle()
                        .fill(Color.dsImagePlaceholder)
                        .shimmer()
                }
            }
            .clipped()
            .overlay(alignment: .topTrailing) { heartBubble }
    }

    private var heartBubble: some View {
        Button(action: onToggleFavourite) {
            Image(systemName: anime.isFavourited ? "heart.fill" : "heart")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(anime.isFavourited ? Color.dsAccent : Color.white)
                .frame(width: 28, height: 28)
                .background(.ultraThinMaterial, in: Circle())
        }
        .buttonStyle(.plain)
        .padding(10)
        .contentShape(Circle())
    }

    private var meta: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(anime.title)
                .font(Typography.cardTitle)
                .tracking(-0.1)
                .foregroundStyle(Color.dsText)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .frame(minHeight: 35, alignment: .top)

            HStack(spacing: 4) {
                Image(systemName: "clock")
                    .font(.system(size: 11, weight: .semibold))
                Text(scheduleText)
                    .font(Typography.meta)
            }
            .foregroundStyle(Color.dsAccentText)
        }
        .padding(.horizontal, Spacing.cardInner)
        .padding(.top, 10)
        .padding(.bottom, Spacing.cardInner)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
