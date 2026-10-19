import Foundation
import Testing
@testable import SuixuCore

@Suite("中国历法与月历边界")
struct CalendarTests {
    let calendar = CalendarEngine.gregorian

    @Test("截图对应日期：2026-10-19 九月初十 丙午马年")
    func referenceDay() {
        let date = CalendarEngine.date(2026, 10, 19)
        let lunar = CalendarEngine.lunar(date)
        #expect(lunar.fullName == "九月初十")
        #expect(lunar.yearName == "丙午年")
        #expect(lunar.zodiac == "马")
        #expect(calendar.component(.weekday, from: date) == 2)
    }

    @Test("春节跨年与大小月除夕")
    func lunarNewYear() {
        #expect(CalendarEngine.festival(CalendarEngine.date(2026, 2, 16)) == "除夕")
        #expect(CalendarEngine.lunar(CalendarEngine.date(2026, 2, 16)).day == 29)
        #expect(CalendarEngine.festival(CalendarEngine.date(2026, 2, 17)) == "春节")
        #expect(CalendarEngine.lunar(CalendarEngine.date(2026, 2, 17)).yearName == "丙午年")
        #expect(CalendarEngine.lunar(CalendarEngine.date(2026, 2, 16)).yearName == "乙巳年")
        #expect(CalendarEngine.festival(CalendarEngine.date(2024, 2, 9)) == "除夕")
        #expect(CalendarEngine.lunar(CalendarEngine.date(2024, 2, 9)).day == 30)
    }

    @Test("闰月不重复传统节日")
    func leapMonth() {
        let leap = CalendarEngine.lunar(CalendarEngine.date(2025, 7, 25))
        #expect(leap.isLeapMonth)
        #expect(leap.fullName == "闰六月初一")
        // 2009 has a leap fifth month: its fifth day is not a second Dragon Boat Festival.
        #expect(CalendarEngine.lunar(CalendarEngine.date(2009, 6, 27)).isLeapMonth)
        #expect(CalendarEngine.festival(CalendarEngine.date(2009, 6, 27)) == nil)
        #expect(CalendarEngine.festival(CalendarEngine.date(2026, 6, 19)) == "端午节")
        #expect(CalendarEngine.festival(CalendarEngine.date(2026, 9, 25)) == "中秋节")
        #expect(CalendarEngine.festival(CalendarEngine.date(2026, 10, 18)) == "重阳")
    }

    @Test("200 年所有月份在两种周起始方式下连续且完整")
    func gridInvariants() {
        for year in CalendarEngine.supportedYears {
            for month in 1...12 {
                let first = CalendarEngine.date(year, month, 1)
                let count = calendar.range(of: .day, in: .month, for: first)!.count
                for monday in [true, false] {
                    let grid = CalendarEngine.monthGrid(containing: first, mondayFirst: monday)
                    #expect(grid.count == 42)
                    #expect(Set(grid).count == 42)
                    #expect(calendar.component(.weekday, from: grid[0]) == (monday ? 2 : 1))
                    #expect(grid.filter { CalendarEngine.sameMonth($0, first) }.count == count)
                    #expect(calendar.dateComponents([.day], from: grid.first!, to: grid.last!).day == 41)
                    let compact = CalendarEngine.monthGrid(containing: first, mondayFirst: monday, compact: true)
                    #expect(compact.count == 35 || compact.count == 42)
                    #expect(compact == Array(grid.prefix(compact.count)))
                    #expect(compact.filter { CalendarEngine.sameMonth($0, first) }.count == count)
                    if compact.count == 42 {
                        #expect(compact.suffix(7).contains { CalendarEngine.sameMonth($0, first) })
                    }
                }
            }
        }
    }

    @Test("月末导航、闰年和支持区间")
    func boundaries() {
        #expect(CalendarEngine.key(CalendarEngine.addingMonths(1, to: CalendarEngine.date(2024, 1, 31))) == "2024-02-29")
        #expect(CalendarEngine.key(CalendarEngine.addingDays(1, to: CalendarEngine.date(2026, 12, 31))) == "2027-01-01")
        #expect(CalendarEngine.clamped(CalendarEngine.date(1900, 12, 31)) == CalendarEngine.minimumDate)
        #expect(CalendarEngine.clamped(CalendarEngine.date(2101, 1, 1)) == CalendarEngine.maximumDate)
        #expect(CalendarEngine.date(from: "2026-02-30") == nil)
        #expect(CalendarEngine.date(from: "invalid") == nil)
    }

    @Test("UTC+8 零点切日，不依赖系统时区")
    func midnight() {
        let before = ISO8601DateFormatter().date(from: "2026-10-18T15:59:59Z")!
        let after = before.addingTimeInterval(1)
        #expect(CalendarEngine.key(before) == "2026-10-18")
        #expect(CalendarEngine.key(after) == "2026-10-19")
        #expect(CalendarEngine.lunar(before).day == 9)
        #expect(CalendarEngine.lunar(after).day == 10)
    }
}

@Suite("权威数据完整性")
struct DataTests {
    @Test("天文台 200 年 × 24 节气")
    func solarData() {
        let terms = SolarTerms.shared
        #expect(terms.dates.count == 4800)
        for year in CalendarEngine.supportedYears {
            let entries = terms.dates.filter { $0.key.hasPrefix("\(year)-") }
            #expect(entries.count == 24)
            #expect(Set(entries.values).count == 24)
        }
        #expect(terms.dates.allSatisfy { CalendarEngine.date(from: $0.key) != nil })
    }

    @Test("2026 全部节气与香港天文台年历一致")
    func referenceSolarTerms() {
        let days = [5, 20, 4, 18, 5, 20, 5, 20, 5, 21, 5, 21, 7, 23, 7, 23, 7, 23, 8, 23, 7, 22, 7, 22]
        let names = "小寒 大寒 立春 雨水 惊蛰 春分 清明 谷雨 立夏 小满 芒种 夏至 小暑 大暑 立秋 处暑 白露 秋分 寒露 霜降 立冬 小雪 大雪 冬至".split(separator: " ").map(String.init)
        for index in 0..<24 {
            #expect(SolarTerms.shared.name(on: CalendarEngine.date(2026, index / 2 + 1, days[index])) == names[index])
        }
        let next = SolarTerms.shared.next(onOrAfter: CalendarEngine.date(2026, 12, 31))!
        #expect(next.name == "小寒")
        #expect(CalendarEngine.key(next.date).hasPrefix("2027-01"))
    }

    @Test("2026 国务院通知：33 个放假日、6 个补班日")
    func official2026() {
        let store = HolidayStore.shared
        let first = CalendarEngine.date(2026, 1, 1)
        let marks = (0..<365).compactMap { store.mark(on: CalendarEngine.addingDays($0, to: first)) }
        #expect(marks.filter { $0.kind == .rest }.count == 33)
        #expect(marks.filter { $0.kind == .work }.count == 6)
        let work = ["2026-01-04", "2026-02-14", "2026-02-28", "2026-05-09", "2026-09-20", "2026-10-10"]
        for date in work { #expect(store.mark(on: CalendarEngine.date(from: date)!)?.kind == .work) }
        #expect(store.mark(on: CalendarEngine.date(2026, 10, 7))?.kind == .rest)
        #expect(store.mark(on: CalendarEngine.date(2026, 10, 8)) == nil)
        #expect(store.mark(on: CalendarEngine.date(2026, 9, 27))?.kind == .rest)
        #expect(store.mark(on: CalendarEngine.date(2026, 9, 28)) == nil)
    }

    @Test("2025 跨月假期及未收录年份不猜测")
    func scheduleBoundaries() {
        let store = HolidayStore.shared
        #expect(store.mark(on: CalendarEngine.date(2025, 2, 4))?.name == "春节")
        #expect(store.mark(on: CalendarEngine.date(2025, 2, 5)) == nil)
        #expect(store.schedule(for: 2025)!.periods.reduce(0) { $0 + $1.dayCount } == 28)
        #expect(store.schedule(for: 2027) == nil)
        #expect(store.mark(on: CalendarEngine.date(2027, 10, 1)) == nil)
        #expect(CalendarEngine.festival(CalendarEngine.date(2027, 10, 1)) == "国庆节")
        for year in store.years {
            var seen = Set<String>()
            for p in year.periods {
                #expect(p.startDate <= p.endDate)
                for offset in 0..<p.dayCount {
                    #expect(seen.insert(CalendarEngine.key(CalendarEngine.addingDays(offset, to: p.startDate))).inserted)
                }
                for date in p.workdays { #expect(seen.insert(date).inserted) }
            }
        }
    }
}
