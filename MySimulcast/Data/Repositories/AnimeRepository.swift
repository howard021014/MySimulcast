import Apollo
import Foundation

final class AnimeRepository: AnimeRepositoryProtocol {
    private let client: ApolloClient

    init(client: ApolloClient = ApolloClientProvider.shared) {
        self.client = client
    }

    func fetchSimulcastSeason(season: Season, year: Int) async throws -> SimulcastSeason {
        let mediaSeason = mediaSeason(from: season)
        var allAnime: [Anime] = []
        var currentPage: Int32 = 1
        var hasNextPage = true

        while hasNextPage {
            let query = AniListAPI.GetSeasonalAnimeQuery(
                season: GraphQLEnum(mediaSeason),
                seasonYear: Int32(year),
                page: .some(currentPage),
                perPage: .some(50)
            )
            let response = try await client.fetch(query: query, cachePolicy: .networkOnly)
            guard let pageData = response.data?.page else { break }

            let anime = (pageData.media ?? []).compactMap { medium -> Anime? in
                guard let medium else { return nil }
                return map(medium: medium)
            }
            allAnime.append(contentsOf: anime)

            hasNextPage = pageData.pageInfo?.hasNextPage ?? false
            currentPage += 1
        }

        return SimulcastSeason(
            season: season,
            year: year,
            anime: allAnime,
            fetchedAt: Date()
        )
    }

    private func mediaSeason(from season: Season) -> AniListAPI.MediaSeason {
        switch season {
        case .winter: return .winter
        case .spring: return .spring
        case .summer: return .summer
        case .fall: return .fall
        }
    }

    private func map(medium: AniListAPI.GetSeasonalAnimeQuery.Data.Page.Medium) -> Anime {
        let title = medium.title?.english ?? medium.title?.romaji ?? "Unknown"
        let coverImageURL = medium.coverImage?.extraLarge.flatMap { URL(string: $0) }
        let thumbnailImageURL = medium.coverImage?.large.flatMap { URL(string: $0) }

        var airingSchedule: AiringSchedule?
        if let next = medium.nextAiringEpisode {
            airingSchedule = AiringSchedule(
                nextEpisode: next.episode,
                nextAiringAt: Date(timeIntervalSince1970: TimeInterval(next.airingAt))
            )
        }

        return Anime(
            id: medium.id,
            title: title,
            coverImageURL: coverImageURL,
            thumbnailImageURL: thumbnailImageURL,
            description: medium.description,
            airingSchedule: airingSchedule,
            isFavourited: false
        )
    }
}
