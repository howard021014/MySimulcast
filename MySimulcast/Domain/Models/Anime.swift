import Foundation

struct Anime: Identifiable, Codable {
    let id: Int
    let title: String
    let coverImageURL: URL?
    let thumbnailImageURL: URL?
    let description: String?
    let airingSchedule: AiringSchedule?
    let season: Season?
    let seasonYear: Int?
    var isFavourited: Bool
}
