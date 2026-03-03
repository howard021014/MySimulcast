import Testing
import Foundation
@testable import MySimulcast

private func makeSimulcastingAnime(id: Int = 1, title: String = "Test Anime") -> Anime {
    Anime(
        id: id,
        title: title,
        coverImageURL: nil,
        thumbnailImageURL: nil,
        description: nil,
        airingSchedule: AiringSchedule(
            nextEpisode: 5,
            nextAiringAt: Date().addingTimeInterval(86400)
        ),
        season: .winter,
        seasonYear: 2026,
        isFavourited: true
    )
}

private func makeNonSimulcastingAnime() -> Anime {
    Anime(
        id: 2,
        title: "Old Anime",
        coverImageURL: nil,
        thumbnailImageURL: nil,
        description: nil,
        airingSchedule: nil,
        season: .summer,
        seasonYear: 2025,
        isFavourited: true
    )
}

@Suite("ScheduleNotificationUseCase")
struct ScheduleNotificationUseCaseTests {

    @Test("Schedules notifications for simulcasting anime when authorized")
    func schedulesWhenAuthorized() async {
        let service = MockNotificationService()
        service.currentStatus = .authorized
        let (currentSeason, currentYear) = Season.current()
        let anime = Anime(
            id: 1, title: "My Anime", coverImageURL: nil, thumbnailImageURL: nil,
            description: nil,
            airingSchedule: AiringSchedule(nextEpisode: 3, nextAiringAt: Date().addingTimeInterval(86400)),
            season: currentSeason, seasonYear: currentYear, isFavourited: true
        )
        let useCase = ScheduleNotificationUseCase(notificationService: service, isNotificationsEnabled: { true })

        await useCase.scheduleForAnime(anime: anime, season: currentSeason, year: currentYear)

        #expect(service.scheduledNotifications.count == 4)
        #expect(service.scheduledNotifications[0].episodeNumber == 3)
        #expect(service.scheduledNotifications[1].episodeNumber == 4)
        #expect(service.scheduledNotifications[2].episodeNumber == 5)
        #expect(service.scheduledNotifications[3].episodeNumber == 6)
    }

    @Test("Does not schedule when anime is not current season")
    func doesNotScheduleNonCurrentSeason() async {
        let service = MockNotificationService()
        service.currentStatus = .authorized
        let anime = Anime(
            id: 1, title: "Old Anime", coverImageURL: nil, thumbnailImageURL: nil,
            description: nil,
            airingSchedule: AiringSchedule(nextEpisode: 5, nextAiringAt: Date().addingTimeInterval(86400)),
            season: .summer, seasonYear: 2025, isFavourited: true
        )
        let useCase = ScheduleNotificationUseCase(notificationService: service, isNotificationsEnabled: { true })

        await useCase.scheduleForAnime(anime: anime, season: .summer, year: 2025)

        #expect(service.scheduledNotifications.isEmpty)
    }

    @Test("Does not schedule when permission is denied")
    func doesNotScheduleWhenDenied() async {
        let service = MockNotificationService()
        service.currentStatus = .denied
        let (currentSeason, currentYear) = Season.current()
        let anime = Anime(
            id: 1, title: "My Anime", coverImageURL: nil, thumbnailImageURL: nil,
            description: nil,
            airingSchedule: AiringSchedule(nextEpisode: 3, nextAiringAt: Date().addingTimeInterval(86400)),
            season: currentSeason, seasonYear: currentYear, isFavourited: true
        )
        let useCase = ScheduleNotificationUseCase(notificationService: service, isNotificationsEnabled: { true })

        await useCase.scheduleForAnime(anime: anime, season: currentSeason, year: currentYear)

        #expect(service.scheduledNotifications.isEmpty)
    }

    @Test("Does not schedule when no airing schedule")
    func doesNotScheduleWithoutAiringSchedule() async {
        let service = MockNotificationService()
        service.currentStatus = .authorized
        let (currentSeason, currentYear) = Season.current()
        let anime = Anime(
            id: 1, title: "No Schedule", coverImageURL: nil, thumbnailImageURL: nil,
            description: nil, airingSchedule: nil,
            season: currentSeason, seasonYear: currentYear, isFavourited: true
        )
        let useCase = ScheduleNotificationUseCase(notificationService: service, isNotificationsEnabled: { true })

        await useCase.scheduleForAnime(anime: anime, season: currentSeason, year: currentYear)

        #expect(service.scheduledNotifications.isEmpty)
    }

    @Test("Notification contains correct title and episode number")
    func notificationContent() async {
        let service = MockNotificationService()
        service.currentStatus = .authorized
        let (currentSeason, currentYear) = Season.current()
        let anime = Anime(
            id: 42, title: "Spy x Family", coverImageURL: nil, thumbnailImageURL: nil,
            description: nil,
            airingSchedule: AiringSchedule(nextEpisode: 7, nextAiringAt: Date().addingTimeInterval(86400)),
            season: currentSeason, seasonYear: currentYear, isFavourited: true
        )
        let useCase = ScheduleNotificationUseCase(notificationService: service, isNotificationsEnabled: { true })

        await useCase.scheduleForAnime(anime: anime, season: currentSeason, year: currentYear)

        let first = service.scheduledNotifications.first
        #expect(first?.animeTitle == "Spy x Family")
        #expect(first?.episodeNumber == 7)
        #expect(first?.animeID == 42)
    }

    @Test("Cancels notifications for unfavourited anime")
    func cancelsOnUnfavourite() async {
        let service = MockNotificationService()
        let useCase = ScheduleNotificationUseCase(notificationService: service, isNotificationsEnabled: { true })

        await useCase.cancelForAnime(id: 42)

        #expect(service.cancelledAnimeIDs == [42])
    }

    @Test("Does not schedule when global toggle is off")
    func doesNotScheduleWhenToggleOff() async {
        let service = MockNotificationService()
        service.currentStatus = .authorized
        let (currentSeason, currentYear) = Season.current()
        let anime = Anime(
            id: 1, title: "My Anime", coverImageURL: nil, thumbnailImageURL: nil,
            description: nil,
            airingSchedule: AiringSchedule(nextEpisode: 3, nextAiringAt: Date().addingTimeInterval(86400)),
            season: currentSeason, seasonYear: currentYear, isFavourited: true
        )
        let useCase = ScheduleNotificationUseCase(notificationService: service, isNotificationsEnabled: { false })

        await useCase.scheduleForAnime(anime: anime, season: currentSeason, year: currentYear)

        #expect(service.scheduledNotifications.isEmpty)
    }
}
