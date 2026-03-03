import SwiftUI

struct NotificationPermissionSheet: View {
    let onEnable: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "bell.badge.fill")
                .font(.system(size: 56))
                .foregroundStyle(.tint)

            Text("Never Miss a New Episode")
                .font(.headline)

            Text("Get notified at 8pm when new episodes of your favourited anime air.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button("Enable Notifications") {
                onEnable()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Button("Not Now") {
                onDismiss()
            }
            .foregroundStyle(.secondary)

            Spacer()
        }
        .padding()
        .presentationDetents([.medium])
    }
}
