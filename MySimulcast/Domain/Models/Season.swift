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
}
