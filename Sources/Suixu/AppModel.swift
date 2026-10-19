import AppKit
import Observation
import SuixuCore

enum SettingsSection: String, CaseIterable {
    case general, menuBar, weather, about
    var title: String {
        switch self {
        case .general: "通用"
        case .menuBar: "菜单栏"
        case .weather: "天气"
        case .about: "关于"
        }
    }
    var symbol: String {
        switch self {
        case .general: "slider.horizontal.3"
        case .menuBar: "menubar.rectangle"
        case .weather: "cloud.sun"
        case .about: "info.circle"
        }
    }
}

enum AppAppearance: String, CaseIterable, Identifiable {
    case system, light, dark
    var id: String { rawValue }
    var title: String {
        switch self { case .system: "跟随系统"; case .light: "浅色"; case .dark: "深色" }
    }
    var native: NSAppearance? {
        switch self { case .system: nil; case .light: NSAppearance(named: .aqua); case .dark: NSAppearance(named: .darkAqua) }
    }
}

enum MenuStyle: String, CaseIterable, Identifiable {
    case compact, standard, lunar
    var id: String { rawValue }
    var title: String {
        switch self {
        case .compact: "简短日期"
        case .standard: "日期与星期"
        case .lunar: "农历"
        }
    }
    func label(at date: Date) -> String {
        switch self {
        case .compact: CalendarEngine.format(date, "M/d")
        case .standard: CalendarEngine.format(date, "M月d日 EEE")
        case .lunar: CalendarEngine.lunar(date).fullName
        }
    }
}

@MainActor @Observable
final class AppModel {
    var now = Date()
    var selectedDate = CalendarEngine.clamped(Date())
    var displayedMonth = CalendarEngine.startOfMonth(CalendarEngine.clamped(Date()))
    var pinned = false { didSet { onPinChanged?() } }
    var showingJump = false
    var showingHolidays = false
    var settingsSection = SettingsSection.general

    var mondayFirst: Bool { didSet { defaults.set(mondayFirst, forKey: "mondayFirst") } }
    var menuStyle: MenuStyle { didSet { defaults.set(menuStyle.rawValue, forKey: "menuStyle"); onMenuChanged?() } }
    var showTime: Bool { didSet { defaults.set(showTime, forKey: "showTime"); onMenuChanged?() } }
    var appearance: AppAppearance { didSet { defaults.set(appearance.rawValue, forKey: "appearance"); onAppearanceChanged?() } }
    var weatherEnabled: Bool { didSet { defaults.set(weatherEnabled, forKey: "weatherEnabled"); onWeatherChanged?() } }
    var weatherCity: String { didSet { defaults.set(weatherCity, forKey: "weatherCity"); onWeatherChanged?() } }

    @ObservationIgnored let defaults: UserDefaults
    @ObservationIgnored var onMenuChanged: (() -> Void)?
    @ObservationIgnored var onAppearanceChanged: (() -> Void)?
    @ObservationIgnored var onPinChanged: (() -> Void)?
    @ObservationIgnored var onWeatherChanged: (() -> Void)?
    @ObservationIgnored var openSettings: (() -> Void)?
    @ObservationIgnored var closePopover: (() -> Void)?
    let holidays = HolidayStore.shared
    let solarTerms = SolarTerms.shared

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        defaults.register(defaults: ["mondayFirst": true, "menuStyle": "standard", "showTime": false, "weatherEnabled": false, "weatherCity": "shenzhen"])
        mondayFirst = defaults.bool(forKey: "mondayFirst")
        menuStyle = MenuStyle(rawValue: defaults.string(forKey: "menuStyle") ?? "") ?? .standard
        showTime = defaults.bool(forKey: "showTime")
        appearance = AppAppearance(rawValue: defaults.string(forKey: "appearance") ?? "") ?? .system
        weatherEnabled = defaults.bool(forKey: "weatherEnabled")
        weatherCity = defaults.string(forKey: "weatherCity") ?? "shenzhen"
    }
    var menuTitle: String {
        var parts = [menuStyle.label(at: now)]
        if showTime { parts.append(CalendarEngine.format(now, "HH:mm")) }
        return parts.filter { !$0.isEmpty }.joined(separator: "  ")
    }
    var year: Int { CalendarEngine.gregorian.component(.year, from: displayedMonth) }
    func select(_ date: Date) {
        selectedDate = CalendarEngine.clamped(date)
        displayedMonth = CalendarEngine.startOfMonth(selectedDate)
    }
    func moveMonth(_ amount: Int) { select(CalendarEngine.addingMonths(amount, to: selectedDate)) }
    func today() { select(now) }
    func refreshClock(at currentDate: Date = Date()) {
        let previous = now
        now = currentDate
        if !CalendarEngine.sameDay(previous, now), CalendarEngine.sameDay(selectedDate, previous) { today() }
        onMenuChanged?()
    }
    func subtitle(for date: Date) -> String {
        CalendarEngine.festival(date) ?? solarTerms.name(on: date) ?? CalendarEngine.lunar(date).shortName
    }
    func accessibilityLabel(for date: Date) -> String {
        var parts = [CalendarEngine.format(date, "yyyy年M月d日 EEEE"), "农历" + CalendarEngine.lunar(date).fullName]
        if let festival = CalendarEngine.festival(date) { parts.append(festival) }
        if let term = solarTerms.name(on: date) { parts.append(term) }
        if let mark = holidays.mark(on: date) { parts.append(mark.description) }
        if CalendarEngine.sameDay(date, now) { parts.append("今天") }
        return parts.joined(separator: "，")
    }
}
