import Testing
import Foundation
@testable import MySimulcast

@Suite("Season")
struct SeasonTests {

    @Test("previous from spring stays in same year")
    func previousFromSpring() {
        let (season, year) = Season.spring.previous(year: 2026)
        #expect(season == .winter)
        #expect(year == 2026)
    }

    @Test("previous from winter decrements year")
    func previousFromWinter() {
        let (season, year) = Season.winter.previous(year: 2026)
        #expect(season == .fall)
        #expect(year == 2025)
    }

    @Test("previous from fall")
    func previousFromFall() {
        let (season, year) = Season.fall.previous(year: 2026)
        #expect(season == .summer)
        #expect(year == 2026)
    }

    @Test("previous from summer")
    func previousFromSummer() {
        let (season, year) = Season.summer.previous(year: 2026)
        #expect(season == .spring)
        #expect(year == 2026)
    }
}

@Suite("SeasonIdentifier")
struct SeasonIdentifierTests {

    @Test("label formats correctly")
    func labelFormat() {
        let id = SeasonIdentifier(season: .winter, year: 2026)
        #expect(id.label == "Winter 2026")
    }

    @Test("id formats correctly")
    func idFormat() {
        let id = SeasonIdentifier(season: .fall, year: 2025)
        #expect(id.id == "fall-2025")
    }

    @Test("list generates correct count")
    func listCount() {
        let list = SeasonIdentifier.list(count: 4)
        #expect(list.count == 4)
    }

    @Test("list is ordered newest to oldest")
    func listOrdering() {
        // Use a fixed date in January 2026 (winter)
        let date = makeDate(year: 2026, month: 1)
        let list = SeasonIdentifier.list(from: date, count: 4)

        #expect(list[0] == SeasonIdentifier(season: .winter, year: 2026))
        #expect(list[1] == SeasonIdentifier(season: .fall, year: 2025))
        #expect(list[2] == SeasonIdentifier(season: .summer, year: 2025))
        #expect(list[3] == SeasonIdentifier(season: .spring, year: 2025))
    }

    @Test("list from spring")
    func listFromSpring() {
        let date = makeDate(year: 2026, month: 4)
        let list = SeasonIdentifier.list(from: date, count: 4)

        #expect(list[0] == SeasonIdentifier(season: .spring, year: 2026))
        #expect(list[1] == SeasonIdentifier(season: .winter, year: 2026))
        #expect(list[2] == SeasonIdentifier(season: .fall, year: 2025))
        #expect(list[3] == SeasonIdentifier(season: .summer, year: 2025))
    }

    private func makeDate(year: Int, month: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = 15
        return Calendar.current.date(from: components)!
    }
}
