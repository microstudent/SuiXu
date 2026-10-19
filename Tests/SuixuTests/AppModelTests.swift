import Foundation
import Testing
import SuixuCore
@testable import Suixu

@Suite("菜单栏与应用状态") @MainActor
struct AppModelTests {
    private func withModel(_ test: (AppModel) -> Void) {
        let suite = "SuixuTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        test(AppModel(defaults: defaults))
    }

    @Test("菜单栏格式与设置持久化")
    func menuFormats() {
        withModel { model in
            model.now = CalendarEngine.date(2026, 10, 19)
            #expect(model.menuTitle == "10月19日 周一")
            #expect(!model.weatherEnabled)
            model.menuStyle = .compact
            #expect(model.menuTitle == "10/19")
            model.menuStyle = .lunar
            #expect(model.menuTitle == "九月初十")
            model.showTime = true
            #expect(model.menuTitle == "九月初十  12:00")
            model.showTime = false
            #expect(model.menuTitle == "九月初十")
            model.mondayFirst = false
            let restored = AppModel(defaults: model.defaults)
            #expect(restored.menuStyle == .lunar)
            #expect(!restored.mondayFirst)
            #expect(!restored.showTime)
        }
    }

    @Test("外观设置可恢复，旧仅图标设置回退为日期")
    func appearancePreferences() {
        withModel { model in
            #expect(model.appearance == .system)
            var changes = 0
            model.onAppearanceChanged = { changes += 1 }
            model.appearance = .dark
            model.defaults.set("icon", forKey: "menuStyle")
            let restored = AppModel(defaults: model.defaults)
            #expect(restored.appearance == .dark)
            #expect(restored.menuStyle == .standard)
            #expect(changes == 1)
        }
    }

    @Test("跨午夜自动跟随今天，但保留用户正在浏览的历史日期")
    func midnightRollover() {
        withModel { model in
            let december = CalendarEngine.date(2026, 12, 31)
            let january = CalendarEngine.date(2027, 1, 1)
            model.now = december
            model.select(december)
            model.refreshClock(at: january)
            #expect(CalendarEngine.sameDay(model.selectedDate, january))
            #expect(model.year == 2027)
            model.select(CalendarEngine.date(2025, 10, 1))
            model.refreshClock(at: CalendarEngine.date(2027, 1, 2))
            #expect(CalendarEngine.key(model.selectedDate) == "2025-10-01")
        }
    }

    @Test("月末切月与极限年份保持状态一致")
    func navigation() {
        withModel { model in
            model.select(CalendarEngine.date(2024, 1, 31))
            model.moveMonth(1)
            #expect(CalendarEngine.key(model.selectedDate) == "2024-02-29")
            #expect(CalendarEngine.key(model.displayedMonth) == "2024-02-01")
            model.select(CalendarEngine.minimumDate)
            model.moveMonth(-1)
            #expect(model.selectedDate == CalendarEngine.minimumDate)
            model.select(CalendarEngine.maximumDate)
            model.moveMonth(1)
            #expect(model.selectedDate == CalendarEngine.maximumDate)
        }
    }
}
