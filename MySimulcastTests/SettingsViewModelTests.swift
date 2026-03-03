import Testing
import Foundation
@testable import MySimulcast

@Suite("SettingsViewModel")
struct SettingsViewModelTests {

    private func makeSUT(
        status: NotificationAuthorizationStatus = .notDetermined,
        favourites: [FavouriteAnime] = []
    ) -> (SettingsViewModel, MockNotificationService) {
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
        let viewModel = SettingsViewModel(manageUseCase: manageUseCase)
        return (viewModel, service)
    }

    @Test("Toggle ON with authorized status schedules all favourites")
    func toggleOnSchedules() async {
        let (currentSeason, currentYear) = Season.current()
        let fav = FavouriteAnime(
            anime: Anime(
                id: 1, title: "Anime", coverImageURL: nil, thumbnailImageURL: nil,
                description: nil,
                airingSchedule: AiringSchedule(nextEpisode: 1, nextAiringAt: Date().addingTimeInterval(86400)),
                season: currentSeason, seasonYear: currentYear, isFavourited: true
            ),
            season: currentSeason, year: currentYear, addedAt: Date()
        )
        let (sut, service) = makeSUT(status: .authorized, favourites: [fav])

        await sut.onToggleChanged(isOn: true)

        #expect(service.scheduledNotifications.count == 4)
    }

    @Test("Toggle OFF cancels all notifications")
    func toggleOffCancels() async {
        let (sut, service) = makeSUT(status: .authorized)

        await sut.onToggleChanged(isOn: false)

        #expect(service.allCancelled == true)
    }

    @Test("Denied status disables toggle")
    func deniedDisablesToggle() async {
        let (sut, _) = makeSUT(status: .denied)

        await sut.onToggleChanged(isOn: true)

        #expect(sut.isSystemPermissionDenied == true)
        #expect(sut.isToggleDisabled == true)
    }

    @Test("Foreground detects denied status")
    func foregroundDetectsDenied() async {
        let (sut, service) = makeSUT(status: .authorized)
        service.currentStatus = .denied

        await sut.onForeground()

        #expect(sut.isSystemPermissionDenied == true)
        #expect(sut.isToggleDisabled == true)
    }
}
