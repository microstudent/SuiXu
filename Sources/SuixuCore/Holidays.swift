import Foundation

public struct HolidayPeriod: Codable, Identifiable, Sendable {
    public let name: String
    public let start: String
    public let end: String
    public let workdays: [String]
    public var id: String { start }
    public var startDate: Date { CalendarEngine.date(from: start)! }
    public var endDate: Date { CalendarEngine.date(from: end)! }
    public var dayCount: Int { CalendarEngine.gregorian.dateComponents([.day], from: startDate, to: endDate).day! + 1 }
}

public struct HolidayYear: Codable, Sendable {
    public let year: Int
    public let source: String
    public let document: String
    public let periods: [HolidayPeriod]
}

public struct HolidayMark: Equatable, Sendable {
    public enum Kind: String, Sendable { case rest, work }
    public let name: String
    public let kind: Kind
    public var symbol: String { kind == .rest ? "休" : "班" }
    public var description: String { name + (kind == .rest ? "假期" : "调休上班") }
}

public struct HolidayStore: Sendable {
    public let years: [HolidayYear]
    private let marks: [String: HolidayMark]
    public static let shared = HolidayStore()

    public init() {
        let url = Bundle.module.url(forResource: "holidays", withExtension: "json")!
        years = try! JSONDecoder().decode([HolidayYear].self, from: Data(contentsOf: url))
        var values: [String: HolidayMark] = [:]
        for year in years {
            for period in year.periods {
                for offset in 0..<period.dayCount {
                    let date = CalendarEngine.addingDays(offset, to: period.startDate)
                    values[CalendarEngine.key(date)] = HolidayMark(name: period.name, kind: .rest)
                }
                for day in period.workdays { values[day] = HolidayMark(name: period.name, kind: .work) }
            }
        }
        marks = values
    }
    public func mark(on date: Date) -> HolidayMark? { marks[CalendarEngine.key(date)] }
    public func schedule(for year: Int) -> HolidayYear? { years.first { $0.year == year } }
    public func hasSchedule(for date: Date) -> Bool { schedule(for: CalendarEngine.gregorian.component(.year, from: date)) != nil }
}
