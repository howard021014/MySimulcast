import SwiftUI

struct EmptyStateView: View {
    let systemImage: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.dsAccentSoft)
                    .frame(width: 92, height: 92)
                Image(systemName: systemImage)
                    .font(.system(size: 38, weight: .regular))
                    .foregroundStyle(Color.dsAccent)
            }

            Text(title)
                .font(.system(size: 18, weight: .bold))
                .tracking(-0.3)
                .foregroundStyle(Color.dsText)

            Text(message)
                .font(Typography.body)
                .foregroundStyle(Color.dsTextDim)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 260)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
