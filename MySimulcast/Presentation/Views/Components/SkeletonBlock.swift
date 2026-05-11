import SwiftUI

struct SkeletonBlock: View {
    var height: CGFloat? = nil
    var radius: CGFloat = 4

    var body: some View {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
            .fill(Color.dsSkeletonBase)
            .frame(height: height)
            .shimmer()
    }
}
