import Foundation

enum NotificationAuthorizationStatus {
    case notDetermined
    case authorized
    case denied
    case provisional
}

struct EpisodeNotification {
    let animeID: Int
    let animeTitle: String
    let episodeNumber: Int
    let airingDate: Date
}

protocol NotificationServiceProtocol {
    func authorizationStatus() async -> NotificationAuthorizationStatus
    func requestAuthorization() async throws -> Bool
    func scheduleEpisodeNotification(_ notification: EpisodeNotification) async throws
    func cancelNotifications(forAnimeID id: Int) async
    func cancelAllNotifications() async
}
