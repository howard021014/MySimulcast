import Testing
import Foundation
@testable import MySimulcast

@Suite("GetFavouritesUseCase")
struct GetFavouritesUseCaseTests {

    @Test("execute returns empty array when repository is empty")
    func emptyRepository() async throws {
        let repo = MockFavouritesRepository()
        let useCase = GetFavouritesUseCase(repository: repo)

        let result = try await useCase.execute()

        #expect(result.isEmpty)
    }

    @Test("execute returns correctly mapped FavouriteAnime")
    func returnsMappedFavourites() async throws {
        let repo = MockFavouritesRepository()
        let anime = Anime(id: 42, title: "My Anime", coverImageURL: nil, thumbnailImageURL: nil,
                          description: nil, airingSchedule: nil, season: nil, seasonYear: nil, isFavourited: true)
        repo.storedFavourites = [
            FavouriteAnime(anime: anime, season: .winter, year: 2026, addedAt: Date())
        ]
        let useCase = GetFavouritesUseCase(repository: repo)

        let result = try await useCase.execute()

        #expect(result.count == 1)
        #expect(result[0].anime.id == 42)
        #expect(result[0].season == .winter)
        #expect(result[0].year == 2026)
    }
}
