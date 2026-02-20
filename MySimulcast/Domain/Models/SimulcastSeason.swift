import Foundation

struct SimulcastSeason: Identifiable, Codable {
    var id: String { "\(season.rawValue)-\(year)" }
    let season: Season
    let year: Int
    let anime: [Anime]
    let fetchedAt: Date
}
