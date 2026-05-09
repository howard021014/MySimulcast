import SwiftUI

struct NotificationPermissionSheet: View {
    let onEnable: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.dsAccentSoft)
                    .frame(width: 92, height: 92)
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 38, weight: .regular))
                    .foregroundStyle(Color.dsAccent)
            }

            Text("Never miss a new episode")
                .font(Typography.detailTitle)
                .tracking(-0.5)
                .foregroundStyle(Color.dsText)
                .multilineTextAlignment(.center)

            Text("Get notified at 8pm when new episodes of your favourited anime air.")
                .font(Typography.body)
                .foregroundStyle(Color.dsTextDim)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .frame(maxWidth: 280)

            Spacer()

            Button {
                onEnable()
            } label: {
                Text("Enable Notifications")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: Radii.field, style: .continuous)
                            .fill(Color.dsAccent)
                    )
            }
            .buttonStyle(.plain)

            Button {
                onDismiss()
            } label: {
                Text("Not Now")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color.dsTextDim)
            }
            .buttonStyle(.plain)
            .padding(.bottom, 8)
        }
        .padding(.horizontal, Spacing.pageHWide)
        .padding(.vertical, 28)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.dsBg.ignoresSafeArea())
        .presentationDetents([.medium])
        .preferredColorScheme(.dark)
    }
}
