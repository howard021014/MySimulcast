import Foundation

struct FavouriteAnime: Identifiable {
    let anime: Anime
    let season: Season?
    let year: Int?
    let addedAt: Date
    let sortOrder: Int
    var id: Int { anime.id }
}
