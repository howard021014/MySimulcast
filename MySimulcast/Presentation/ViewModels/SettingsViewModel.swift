import Foundation
import SwiftUI

@Observable final class SettingsViewModel {
    var isNotificationsEnabled: Bool {
        get { access(keyPath: \.isNotificationsEnabled); return UserDefaults.standard.bool(forKey: "notificationsEnabled") }
        set { withMutation(keyPath: \.isNotificationsEnabled) { UserDefaults.standard.set(newValue, forKey: "notificationsEnabled") } }
    }
    var isToggleDisabled = false
    var isSystemPermissionDenied = false

    private var lastTimezoneID: String {
        get { UserDefaults.standard.string(forKey: "lastTimezoneID") ?? TimeZone.current.identifier }
        set { UserDefaults.standard.set(newValue, forKey: "lastTimezoneID") }
    }

    private let manageUseCase: ManageNotificationsUseCase

    init(manageUseCase: ManageNotificationsUseCase) {
        self.manageUseCase = manageUseCase
    }

    func onToggleChanged(isOn: Bool) async {
        if isOn {
            let status = await manageUseCase.authorizationStatus()
            switch status {
            case .notDetermined:
                let granted = (try? await manageUseCase.requestAuthorization()) ?? false
                if granted {
                    isNotificationsEnabled = true
                    await manageUseCase.scheduleAllFavourites()
                } else {
                    isNotificationsEnabled = false
                    isSystemPermissionDenied = true
                    isToggleDisabled = true
                }
            case .authorized, .provisional:
                isNotificationsEnabled = true
                await manageUseCase.scheduleAllFavourites()
            case .denied:
                isNotificationsEnabled = false
                isSystemPermissionDenied = true
                isToggleDisabled = true
            }
        } else {
            isNotificationsEnabled = false
            await manageUseCase.cancelAll()
        }
    }

    func onForeground() async {
        let status = await manageUseCase.authorizationStatus()
        switch status {
        case .authorized, .provisional:
            isSystemPermissionDenied = false
            isToggleDisabled = false
            // Check timezone change
            let currentTZ = TimeZone.current.identifier
            if currentTZ != lastTimezoneID {
                lastTimezoneID = currentTZ
                if isNotificationsEnabled {
                    await manageUseCase.scheduleAllFavourites()
                }
            }
        case .denied:
            isSystemPermissionDenied = true
            isToggleDisabled = true
            if isNotificationsEnabled {
                isNotificationsEnabled = false
            }
        case .notDetermined:
            isSystemPermissionDenied = false
            isToggleDisabled = false
        }
    }

    func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}
