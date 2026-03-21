import Foundation

enum Season: String, Codable, CaseIterable {
    case winter
    case spring
    case summer
    case fall

    static func current(for date: Date = Date()) -> (Season, Int) {
        let calendar = Calendar.current
        let month = calendar.component(.month, from: date)
        let year = calendar.component(.year, from: date)

        let season: Season
        switch month {
        case 1...3: season = .winter
        case 4...6: season = .spring
        case 7...9: season = .summer
        default: season = .fall
        }

        return (season, year)
    }

    func previous(year: Int) -> (Season, Int) {
        switch self {
        case .winter: return (.fall, year - 1)
        case .spring: return (.winter, year)
        case .summer: return (.spring, year)
        case .fall: return (.summer, year)
        }
    }
}

struct SeasonIdentifier: Hashable, Identifiable, Codable {
    let season: Season
    let year: Int

    var id: String { "\(season.rawValue)-\(year)" }
    var label: String { "\(season.rawValue.capitalized) \(year)" }

    static func list(from date: Date = Date(), count: Int = 4) -> [SeasonIdentifier] {
        var (season, year) = Season.current(for: date)
        var result: [SeasonIdentifier] = []
        for _ in 0..<count {
            result.append(SeasonIdentifier(season: season, year: year))
            (season, year) = season.previous(year: year)
        }
        return result
    }
}
