import SwiftUI

struct SearchResultRowSkeleton: View {
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            SkeletonBlock(radius: Radii.thumb)
                .frame(width: 50, height: 70)

            GeometryReader { proxy in
                let w = proxy.size.width
                VStack(alignment: .leading, spacing: 3) {
                    SkeletonBlock(height: 13, radius: 4)
                        .frame(width: w * 0.70)
                    SkeletonBlock(height: 10, radius: 4)
                        .frame(width: w * 0.45)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 4)
            }
            .frame(height: 70)

            VStack(spacing: 16) {
                SkeletonBlock(height: 18, radius: 4)
                    .frame(width: 20)
                SkeletonBlock(height: 14, radius: 4)
                    .frame(width: 16)
            }
            .padding(.top, 4)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 4)
    }
}
