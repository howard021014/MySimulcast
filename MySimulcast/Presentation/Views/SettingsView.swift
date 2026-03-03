import SwiftUI

struct SettingsView: View {
    @Environment(SettingsViewModel.self) private var viewModel
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        @Bindable var viewModel = viewModel
        NavigationStack {
            Form {
                Section {
                    Toggle("Episode Notifications", isOn: $viewModel.isNotificationsEnabled)
                        .disabled(viewModel.isToggleDisabled)
                        .onChange(of: viewModel.isNotificationsEnabled) { _, newValue in
                            Task { await viewModel.onToggleChanged(isOn: newValue) }
                        }

                    if viewModel.isSystemPermissionDenied {
                        Button("Open Notification Settings") {
                            viewModel.openSystemSettings()
                        }
                    }
                } header: {
                    Text("Notifications")
                } footer: {
                    if viewModel.isSystemPermissionDenied {
                        Text("Notifications are disabled in system settings. Tap above to enable them.")
                    } else {
                        Text("Get notified at 8pm when new episodes of your favourited anime air.")
                    }
                }
            }
            .navigationTitle("Settings")
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    Task { await viewModel.onForeground() }
                }
            }
        }
    }
}
