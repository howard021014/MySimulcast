import Foundation

struct ScheduleNotificationUseCase {
    private let notificationService: NotificationServiceProtocol
    private let isNotificationsEnabled: () -> Bool

    init(notificationService: NotificationServiceProtocol, isNotificationsEnabled: @escaping () -> Bool) {
        self.notificationService = notificationService
        self.isNotificationsEnabled = isNotificationsEnabled
    }

    func scheduleForAnime(anime: Anime, season: Season, year: Int) async {
        let (currentSeason, currentYear) = Season.current()
        guard season == currentSeason && year == currentYear else { return }
        guard let schedule = anime.airingSchedule else { return }
        guard isNotificationsEnabled() else { return }

        let status = await notificationService.authorizationStatus()
        guard status == .authorized || status == .provisional else { return }

        let calendar = Calendar.current
        let now = Date()

        for weekOffset in 0..<4 {
            let episodeNumber = schedule.nextEpisode + weekOffset
            let airingDate = calendar.date(byAdding: .weekOfYear, value: weekOffset, to: schedule.nextAiringAt)!

            var eightPM = calendar.dateComponents([.year, .month, .day], from: airingDate)
            eightPM.hour = 20
            eightPM.minute = 0
            eightPM.second = 0
            guard let notificationDate = calendar.date(from: eightPM), notificationDate > now else { continue }

            let notification = EpisodeNotification(
                animeID: anime.id,
                animeTitle: anime.title,
                episodeNumber: episodeNumber,
                airingDate: airingDate
            )
            try? await notificationService.scheduleEpisodeNotification(notification)
        }
    }

    func cancelForAnime(id: Int) async {
        await notificationService.cancelNotifications(forAnimeID: id)
    }

    func authorizationStatus() async -> NotificationAuthorizationStatus {
        await notificationService.authorizationStatus()
    }

    func requestAuthorization() async throws -> Bool {
        try await notificationService.requestAuthorization()
    }
}
