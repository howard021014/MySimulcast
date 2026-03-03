import Foundation
@testable import MySimulcast

final class MockNotificationService: NotificationServiceProtocol {
    var currentStatus: NotificationAuthorizationStatus = .notDetermined
    var authorizationGranted = true
    var scheduledNotifications: [EpisodeNotification] = []
    var cancelledAnimeIDs: [Int] = []
    var allCancelled = false

    func authorizationStatus() async -> NotificationAuthorizationStatus {
        currentStatus
    }

    func requestAuthorization() async throws -> Bool {
        if authorizationGranted {
            currentStatus = .authorized
        }
        return authorizationGranted
    }

    func scheduleEpisodeNotification(_ notification: EpisodeNotification) async throws {
        scheduledNotifications.append(notification)
    }

    func cancelNotifications(forAnimeID id: Int) async {
        cancelledAnimeIDs.append(id)
        scheduledNotifications.removeAll { $0.animeID == id }
    }

    func cancelAllNotifications() async {
        allCancelled = true
        scheduledNotifications.removeAll()
    }
}
