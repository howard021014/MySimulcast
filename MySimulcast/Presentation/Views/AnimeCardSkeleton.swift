import SwiftUI

struct AnimeCardSkeleton: View {
    var body: some View {
        VStack(spacing: 0) {
            SkeletonBlock(radius: 0)
                .aspectRatio(3.0 / 4.0, contentMode: .fit)

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

    private var meta: some View {
        GeometryReader { proxy in
            let innerWidth = max(proxy.size.width - 2 * Spacing.cardInner, 0)
            VStack(alignment: .leading, spacing: 6) {
                VStack(alignment: .leading, spacing: 6) {
                    SkeletonBlock(height: 12, radius: 4)
                        .frame(width: innerWidth * 0.92)
                    SkeletonBlock(height: 12, radius: 4)
                        .frame(width: innerWidth * 0.64)
                }
                .frame(minHeight: 35, alignment: .top)

                SkeletonBlock(height: 9, radius: 4)
                    .frame(width: innerWidth * 0.54)
            }
            .padding(.horizontal, Spacing.cardInner)
            .padding(.top, 10)
            .padding(.bottom, Spacing.cardInner)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: 75)
    }
}
