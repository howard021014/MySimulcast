import SwiftUI

struct SettingsView: View {
    @Environment(SettingsViewModel.self) private var viewModel
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        @Bindable var vm = viewModel
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    largeTitle

                    sectionHeader("NOTIFICATIONS")

                    groupContainer {
                        VStack(spacing: 0) {
                            row {
                                Toggle(isOn: $vm.isNotificationsEnabled) {
                                    Text("Episode Notifications")
                                        .font(Typography.rowTitle)
                                        .foregroundStyle(Color.dsText)
                                }
                                .tint(Color.dsAccent)
                                .disabled(viewModel.isToggleDisabled)
                                .onChange(of: viewModel.isNotificationsEnabled) { _, newValue in
                                    Task { await viewModel.onToggleChanged(isOn: newValue) }
                                }
                            }

                            if viewModel.isSystemPermissionDenied {
                                Rectangle()
                                    .fill(Color.dsSeparator)
                                    .frame(height: 0.5)
                                row {
                                    Button {
                                        viewModel.openSystemSettings()
                                    } label: {
                                        HStack {
                                            Text("Open Notification Settings")
                                                .font(Typography.rowTitle)
                                                .foregroundStyle(Color.dsAccent)
                                            Spacer()
                                            Image(systemName: "chevron.right")
                                                .font(.system(size: 13, weight: .semibold))
                                                .foregroundStyle(Color.dsTextFaint)
                                        }
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }

                    sectionFooter(
                        viewModel.isSystemPermissionDenied
                        ? "Notifications are disabled in system settings. Tap above to enable them."
                        : "Get notified at 8pm when new episodes of your favourited anime air."
                    )

                    Spacer(minLength: Spacing.tabClearance)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .dsBackgroundGradient()
            .toolbar(.hidden, for: .navigationBar)
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    Task { await viewModel.onForeground() }
                }
            }
        }
    }

    private var largeTitle: some View {
        Text("Settings")
            .font(Typography.largeTitle)
            .tracking(-0.8)
            .foregroundStyle(Color.dsText)
            .padding(.horizontal, Spacing.pageH)
            .padding(.top, 8)
            .padding(.bottom, 18)
    }

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(Typography.groupHeader)
            .tracking(0.8)
            .foregroundStyle(Color.dsTextDim)
            .padding(.horizontal, Spacing.pageHWide)
            .padding(.bottom, 6)
            .padding(.top, 12)
    }

    private func sectionFooter(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12))
            .foregroundStyle(Color.dsTextFaint)
            .padding(.horizontal, Spacing.pageHWide)
            .padding(.top, 8)
    }

    @ViewBuilder
    private func groupContainer<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .background(
                RoundedRectangle(cornerRadius: Radii.group, style: .continuous)
                    .fill(Color.dsCard)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Radii.group, style: .continuous)
                    .strokeBorder(Color.dsSeparator, lineWidth: 1)
            )
            .padding(.horizontal, Spacing.pageH)
    }

    private func row<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
    }
}
