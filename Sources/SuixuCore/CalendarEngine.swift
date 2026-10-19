import Foundation

public struct LunarDate: Equatable, Sendable {
    public let month: Int
    public let day: Int
    public let isLeapMonth: Bool
    public let cyclicalYear: Int
    public var monthName: String {
        (isLeapMonth ? "闰" : "") + ["正月", "二月", "三月", "四月", "五月", "六月", "七月", "八月", "九月", "十月", "冬月", "腊月"][month - 1]
    }
    public var dayName: String {
        let names = ["初一", "初二", "初三", "初四", "初五", "初六", "初七", "初八", "初九", "初十", "十一", "十二", "十三", "十四", "十五", "十六", "十七", "十八", "十九", "二十", "廿一", "廿二", "廿三", "廿四", "廿五", "廿六", "廿七", "廿八", "廿九", "三十"]
        return names[day - 1]
    }
    public var shortName: String { day == 1 ? monthName : dayName }
    public var fullName: String { monthName + dayName }
    public var yearName: String {
        let stems = Array("甲乙丙丁戊己庚辛壬癸")
        let branches = Array("子丑寅卯辰巳午未申酉戌亥")
        return "\(stems[(cyclicalYear - 1) % 10])\(branches[(cyclicalYear - 1) % 12])年"
    }
    public var zodiac: String { String(Array("鼠牛虎兔龙蛇马羊猴鸡狗猪")[(cyclicalYear - 1) % 12]) }
}

public enum CalendarEngine {
    // Chinese civil dates and solar terms use UTC+8, independently of the Mac's locale.
    public static let timeZone = TimeZone(secondsFromGMT: 8 * 3600)!
    public static let gregorian: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = timeZone
        c.locale = Locale(identifier: "zh_CN")
        return c
    }()
    public static let chinese: Calendar = {
        var c = Calendar(identifier: .chinese)
        c.timeZone = timeZone
        return c
    }()
    public static let supportedYears = 1901...2100
    public static let minimumDate = date(1901, 1, 1)
    public static let maximumDate = date(2100, 12, 31)

    public static func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        gregorian.date(from: DateComponents(year: year, month: month, day: day, hour: 12))!
    }
    public static func date(from key: String) -> Date? {
        let p = key.split(separator: "-").compactMap { Int($0) }
        guard p.count == 3, (1...12).contains(p[1]), (1...31).contains(p[2]) else { return nil }
        let result = date(p[0], p[1], p[2])
        return self.key(result) == key ? result : nil
    }
    public static func key(_ date: Date) -> String {
        let c = gregorian.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year!, c.month!, c.day!)
    }
    public static func format(_ date: Date, _ pattern: String) -> String {
        let f = DateFormatter()
        f.calendar = gregorian
        f.locale = Locale(identifier: "zh_CN")
        f.timeZone = timeZone
        f.dateFormat = pattern
        return f.string(from: date)
    }
    public static func lunar(_ date: Date) -> LunarDate {
        let c = chinese.dateComponents([.year, .month, .day, .isLeapMonth], from: date)
        return LunarDate(month: c.month!, day: c.day!, isLeapMonth: c.isLeapMonth ?? false, cyclicalYear: c.year!)
    }
    public static func startOfMonth(_ date: Date) -> Date {
        let c = gregorian.dateComponents([.year, .month], from: date)
        return self.date(c.year!, c.month!, 1)
    }
    public static func addingDays(_ count: Int, to date: Date) -> Date {
        gregorian.date(byAdding: .day, value: count, to: date)!
    }
    public static func addingMonths(_ count: Int, to date: Date) -> Date {
        gregorian.date(byAdding: .month, value: count, to: date)!
    }
    public static func clamped(_ date: Date) -> Date { min(max(date, minimumDate), maximumDate) }
    public static func isSupported(_ date: Date) -> Bool { supportedYears.contains(gregorian.component(.year, from: date)) }
    public static func sameDay(_ lhs: Date, _ rhs: Date) -> Bool { gregorian.isDate(lhs, inSameDayAs: rhs) }
    public static func sameMonth(_ lhs: Date, _ rhs: Date) -> Bool { gregorian.isDate(lhs, equalTo: rhs, toGranularity: .month) }
    public static func monthGrid(containing date: Date, mondayFirst: Bool, compact: Bool = false) -> [Date] {
        let first = startOfMonth(date)
        let weekday = gregorian.component(.weekday, from: first)
        let offset = (weekday - (mondayFirst ? 2 : 1) + 7) % 7
        let days = gregorian.range(of: .day, in: .month, for: first)!.count
        let cellCount = compact ? max(35, ((offset + days + 6) / 7) * 7) : 42
        return (0..<cellCount).map { addingDays($0 - offset, to: first) }
    }
    public static func festival(_ date: Date) -> String? {
        let c = gregorian.dateComponents([.month, .day], from: date)
        switch (c.month!, c.day!) {
        case (1, 1): return "元旦"
        case (5, 1): return "劳动节"
        case (10, 1): return "国庆节"
        default: break
        }
        let l = lunar(date)
        guard !l.isLeapMonth else { return nil }
        switch (l.month, l.day) {
        case (1, 1): return "春节"
        case (1, 15): return "元宵节"
        case (5, 5): return "端午节"
        case (7, 7): return "七夕"
        case (8, 15): return "中秋节"
        case (9, 9): return "重阳"
        case (12, 8): return "腊八"
        default:
            let next = lunar(addingDays(1, to: date))
            return next.month == 1 && next.day == 1 && !next.isLeapMonth ? "除夕" : nil
        }
    }
}

public struct SolarTerms: Sendable {
    public let dates: [String: String]
    public static let shared = SolarTerms()
    public init() {
        // A missing or malformed shipped resource is a build defect, not an empty calendar.
        let url = Bundle.module.url(forResource: "solar-terms", withExtension: "json")!
        dates = try! JSONDecoder().decode([String: String].self, from: Data(contentsOf: url))
    }
    public func name(on date: Date) -> String? { dates[CalendarEngine.key(date)] }
    public func next(onOrAfter date: Date) -> (date: Date, name: String)? {
        for offset in 0...32 {
            let day = CalendarEngine.addingDays(offset, to: date)
            if let name = name(on: day) { return (day, name) }
        }
        return nil
    }
}
