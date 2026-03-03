import Testing
import Foundation
@testable import MySimulcast

@Suite("ManageNotificationsUseCase")
struct ManageNotificationsUseCaseTests {

    private func makeSUT(
        favourites: [FavouriteAnime] = [],
        status: NotificationAuthorizationStatus = .authorized
    ) -> (ManageNotificationsUseCase, MockNotificationService, MockFavouritesRepository) {
        let service = MockNotificationService()
        service.currentStatus = status
        let repo = MockFavouritesRepository()
        repo.storedFavourites = favourites
        let scheduleUseCase = ScheduleNotificationUseCase(notificationService: service, isNotificationsEnabled: { true })
        let manageUseCase = ManageNotificationsUseCase(
            scheduleUseCase: scheduleUseCase,
            favouritesRepository: repo,
            notificationService: service
        )
        return (manageUseCase, service, repo)
    }

    @Test("Schedule all favourites schedules only current-season anime")
    func scheduleAllOnlyCurrentSeason() async {
        let (currentSeason, currentYear) = Season.current()
        let simulcasting = FavouriteAnime(
            anime: Anime(
                id: 1, title: "Current", coverImageURL: nil, thumbnailImageURL: nil,
                description: nil,
                airingSchedule: AiringSchedule(nextEpisode: 1, nextAiringAt: Date().addingTimeInterval(86400)),
                season: currentSeason, seasonYear: currentYear, isFavourited: true
            ),
            season: currentSeason, year: currentYear, addedAt: Date()
        )
        let oldAnime = FavouriteAnime(
            anime: Anime(
                id: 2, title: "Old", coverImageURL: nil, thumbnailImageURL: nil,
                description: nil, airingSchedule: nil,
                season: .summer, seasonYear: 2024, isFavourited: true
            ),
            season: .summer, year: 2024, addedAt: Date()
        )
        let (sut, service, _) = makeSUT(favourites: [simulcasting, oldAnime])

        await sut.scheduleAllFavourites()

        #expect(service.allCancelled == true)
        #expect(service.scheduledNotifications.count == 4)
        #expect(service.scheduledNotifications.allSatisfy { $0.animeID == 1 })
    }

    @Test("Cancel all removes all pending notifications")
    func cancelAll() async {
        let (sut, service, _) = makeSUT()

        await sut.cancelAll()

        #expect(service.allCancelled == true)
    }

    @Test("ReSync reschedules with fresh data for favourited anime")
    func reSyncReschedules() async {
        let (currentSeason, currentYear) = Season.current()
        let fav = FavouriteAnime(
            anime: Anime(
                id: 1, title: "Anime", coverImageURL: nil, thumbnailImageURL: nil,
                description: nil,
                airingSchedule: AiringSchedule(nextEpisode: 5, nextAiringAt: Date().addingTimeInterval(86400)),
                season: currentSeason, seasonYear: currentYear, isFavourited: true
            ),
            season: currentSeason, year: currentYear, addedAt: Date()
        )
        let (sut, service, _) = makeSUT(favourites: [fav])

        let freshAnime = [
            Anime(
                id: 1, title: "Anime", coverImageURL: nil, thumbnailImageURL: nil,
                description: nil,
                airingSchedule: AiringSchedule(nextEpisode: 6, nextAiringAt: Date().addingTimeInterval(172800)),
                season: currentSeason, seasonYear: currentYear, isFavourited: true
            )
        ]

        await sut.reSyncIfNeeded(currentAnime: freshAnime, season: currentSeason, year: currentYear)

        #expect(service.allCancelled == true)
        #expect(service.scheduledNotifications.first?.episodeNumber == 6)
    }
}
