import Foundation
import UserNotifications

final class NotificationManager: NotificationServiceProtocol {
    private let center = UNUserNotificationCenter.current()

    func authorizationStatus() async -> NotificationAuthorizationStatus {
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .notDetermined: return .notDetermined
        case .authorized: return .authorized
        case .denied: return .denied
        case .provisional: return .provisional
        case .ephemeral: return .authorized
        @unknown default: return .denied
        }
    }

    func requestAuthorization() async throws -> Bool {
        try await center.requestAuthorization(options: [.alert, .badge, .sound])
    }

    func scheduleEpisodeNotification(_ notification: EpisodeNotification) async throws {
        let content = UNMutableNotificationContent()
        content.title = "MySimulcast"
        content.body = "\(notification.animeTitle) Episode \(notification.episodeNumber) airing now!"
        content.sound = .default

        let trigger = makeTrigger(for: notification.airingDate)
        let identifier = "anime-\(notification.animeID)-ep-\(notification.episodeNumber)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        try await center.add(request)
    }

    func cancelNotifications(forAnimeID id: Int) async {
        let prefix = "anime-\(id)-ep-"
        let pending = await center.pendingNotificationRequests()
        let matching = pending.filter { $0.identifier.hasPrefix(prefix) }.map(\.identifier)
        center.removePendingNotificationRequests(withIdentifiers: matching)
    }

    func cancelAllNotifications() async {
        center.removeAllPendingNotificationRequests()
    }

    private func makeTrigger(for airingDate: Date) -> UNNotificationTrigger {
        #if DEBUG
        return UNTimeIntervalNotificationTrigger(timeInterval: 10, repeats: false)
        #else
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: airingDate)
        components.hour = 20
        components.minute = 0
        components.second = 0
        return UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        #endif
    }
}
