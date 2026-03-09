import SwiftUI

struct AnimeCardView: View {
    let anime: Anime
    let scheduleText: String
    let onToggleFavourite: () -> Void

    @State private var isFlipped = false
    @State private var rotationAngle: Double = 0
    @State private var isAnimating = false
    @State private var showDetailSheet = false

    var body: some View {
        Button(action: handleCardTap) {
            ZStack {
                frontFace
                    .opacity(rotationAngle < 90 ? 1 : 0)

                backFace
                    .opacity(rotationAngle >= 90 ? 1 : 0)
                    .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
            }
            .rotation3DEffect(.degrees(rotationAngle), axis: (x: 0, y: 1, z: 0), perspective: 0.3)
        }
        .buttonStyle(PressableCardStyle())
        .sheet(isPresented: $showDetailSheet) {
            AnimeDetailSheet(anime: anime)
        }
    }

    private var frontFace: some View {
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
                            .shimmer()
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

    private var backFace: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(anime.title)
                .font(.subheadline)
                .bold()
                .lineLimit(2)

            Text(anime.description ?? "No description available.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(3)

            Spacer(minLength: 0)

            Button {
                showDetailSheet = true
            } label: {
                HStack {
                    Text("Details")
                        .font(.subheadline)
                    Spacer()
                    Image(systemName: "chevron.right")
                }
                .foregroundStyle(.primary)
            }
            .buttonStyle(.plain)
            .allowsHitTesting(rotationAngle >= 90)
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func handleCardTap() {
        guard !isAnimating else { return }
        isAnimating = true
        isFlipped.toggle()
        let target: Double = isFlipped ? 180 : 0
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            rotationAngle = target
        } completion: {
            isAnimating = false
        }
    }
}
