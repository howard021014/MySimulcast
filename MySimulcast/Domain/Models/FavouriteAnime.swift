import Foundation

struct FavouriteAnime: Identifiable {
    let anime: Anime
    let season: Season
    let year: Int
    let addedAt: Date
    var id: Int { anime.id }
}
