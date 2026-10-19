import AppKit
import SwiftUI
import SuixuCore

enum Palette {
    // Keep selected-day text white with sufficient contrast in both appearances.
    static let selection = Color(red: 0.72, green: 0.23, blue: 0.18)
    static let accent = Color(nsColor: NSColor(name: nil) { appearance in
        appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            ? NSColor(srgbRed: 1, green: 0.62, blue: 0.54, alpha: 1)
            : NSColor(srgbRed: 0.72, green: 0.23, blue: 0.18, alpha: 1)
    })
    static let jade = Color(nsColor: NSColor(name: nil) { appearance in
        appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            ? NSColor(srgbRed: 0.65, green: 0.85, blue: 0.77, alpha: 1)
            : NSColor(srgbRed: 0.22, green: 0.42, blue: 0.35, alpha: 1)
    })
    // Secondary labels on a translucent dark popover need more contrast than
    // the default secondary vibrancy. Keep system label hues and raise alpha.
    static let supportingText = Color(nsColor: NSColor(name: nil) { appearance in
        let dark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        return (dark ? NSColor.labelColor.withAlphaComponent(0.84) : NSColor.secondaryLabelColor)
    })
}

struct CalendarView: View {
    @Bindable var model: AppModel
    @Bindable var weather: WeatherModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        VStack(spacing: 0) {
            masthead
            monthHeader.padding(.top, 12).padding(.bottom, 14)
            weekdays.padding(.bottom, 8)
            calendarGrid
            Divider().padding(.top, 12).padding(.bottom, 12)
            selectedDay
            seasonLine.padding(.top, 12)
            if model.weatherEnabled { weatherLine.padding(.top, 12) }
        }
        .padding(18)
        .frame(width: 420)
        .background {
            if reduceTransparency {
                Color(nsColor: .windowBackgroundColor)
            } else if colorScheme == .dark {
                // Retain the native behind-window blur; a translucent scrim prevents
                // bright windows beneath it from washing out small calendar labels.
                Color.black.opacity(contrast == .increased ? 0.66 : 0.36)
            } else {
                // NSPopover already provides a behind-window material. Do not stack
                // an in-window SwiftUI material on top of that native surface.
                Color.clear
            }
        }
        .tint(Palette.accent)
        .sheet(isPresented: $model.showingHolidays) { HolidayListView(model: model) }
    }

    private var masthead: some View {
        HStack(spacing: 7) {
            Image(systemName: "sun.horizon").font(.system(size: 16, weight: .medium)).foregroundStyle(Palette.accent)
            Text("岁序").font(.system(size: 14, weight: .semibold))
            Spacer()
            Button { model.pinned.toggle() } label: {
                Image(systemName: model.pinned ? "pin.fill" : "pin")
                    .frame(width: 32, height: 32).contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(model.pinned ? Palette.accent : Palette.supportingText)
            .help(model.pinned ? "取消固定浮层" : "固定浮层")
            .accessibilityLabel(model.pinned ? "取消固定浮层" : "固定浮层")
            Menu {
                Button("\(String(model.year))年中国节假日", systemImage: "calendar.badge.clock") { model.showingHolidays = true }
                Divider()
                Button("设置…", systemImage: "gearshape") { model.openSettings?() }
                Button("退出岁序", systemImage: "power") { NSApp.terminate(nil) }
            } label: {
                Image(systemName: "ellipsis").frame(width: 32, height: 32).contentShape(Rectangle())
            }
            .menuStyle(.borderlessButton).menuIndicator(.hidden).fixedSize()
            .help("节假日、设置与退出").accessibilityLabel("更多选项")
        }
    }

    private var monthHeader: some View {
        HStack(alignment: .center) {
            Button { model.showingJump = true } label: {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(CalendarEngine.format(model.displayedMonth, "M月"))
                        .font(.system(size: 29, weight: .semibold, design: .rounded))
                    Text(String(model.year)).font(.system(size: 17, weight: .regular)).foregroundStyle(Palette.supportingText)
                    Image(systemName: "chevron.down").font(.system(size: 9, weight: .semibold)).foregroundStyle(.tertiary)
                }
            }
            .buttonStyle(.plain).help("跳转年月").accessibilityLabel("\(String(model.year))年\(CalendarEngine.format(model.displayedMonth, "M月"))，跳转年月")
            .popover(isPresented: $model.showingJump, arrowEdge: .top) { MonthJumpView(model: model) }
            Spacer(minLength: 8)
            HStack(spacing: 0) {
                Button { navigate(-1) } label: {
                    Image(systemName: "chevron.left").frame(width: 44, height: 40).contentShape(Rectangle())
                }
                    .disabled(model.displayedMonth <= CalendarEngine.startOfMonth(CalendarEngine.minimumDate))
                    .help("上个月（⌘←）").accessibilityLabel("上个月")
                Button { model.today() } label: {
                    Text("今天").font(.system(size: 12, weight: .medium)).frame(width: 44, height: 40).contentShape(Rectangle())
                }.help("回到今天（空格）")
                Button { navigate(1) } label: {
                    Image(systemName: "chevron.right").frame(width: 44, height: 40).contentShape(Rectangle())
                }
                    .disabled(model.displayedMonth >= CalendarEngine.startOfMonth(CalendarEngine.maximumDate))
                    .help("下个月（⌘→）").accessibilityLabel("下个月")
            }
            .buttonStyle(.plain)
            .font(.system(size: 11, weight: .semibold))
            .padding(2)
            .glassEffect(.regular, in: .capsule)
        }
    }

    private var weekdays: some View {
        let days = model.mondayFirst ? ["一", "二", "三", "四", "五", "六", "日"] : ["日", "一", "二", "三", "四", "五", "六"]
        return HStack(spacing: 3) {
            ForEach(days, id: \.self) { day in
                Text(day).font(.system(size: 11, weight: .medium))
                    .foregroundStyle(day == "六" || day == "日" ? Palette.accent : Palette.supportingText)
                    .frame(maxWidth: .infinity)
            }
        }
        .accessibilityHidden(true)
    }

    private var calendarGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 3), count: 7), spacing: 4) {
            ForEach(CalendarEngine.monthGrid(containing: model.displayedMonth, mondayFirst: model.mondayFirst, compact: true), id: \.self) { date in
                DayCell(date: date, model: model)
            }
        }
    }

    private var selectedDay: some View {
        let lunar = CalendarEngine.lunar(model.selectedDate)
        let isToday = CalendarEngine.sameDay(model.selectedDate, model.now)
        return HStack(alignment: .center, spacing: 15) {
            Text(CalendarEngine.format(model.selectedDate, "dd"))
                .font(.system(size: 43, weight: .light, design: .rounded))
                .monospacedDigit().foregroundStyle(isToday ? Palette.accent : .primary)
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 7) {
                    Text(lunar.fullName).font(.system(size: 15, weight: .medium))
                    if isToday { Text("今天").font(.system(size: 10, weight: .medium)).foregroundStyle(Palette.accent).padding(.horizontal, 6).padding(.vertical, 2).background(Palette.accent.opacity(0.09), in: Capsule()) }
                }
                Text("\(lunar.yearName) · \(lunar.zodiac)年  \(CalendarEngine.format(model.selectedDate, "EEEE"))")
                    .font(.system(size: 11)).foregroundStyle(Palette.supportingText)
            }
            Spacer(minLength: 0)
            if let mark = model.holidays.mark(on: model.selectedDate) {
                VStack(alignment: .trailing, spacing: 5) {
                    Text(mark.kind == .rest ? "休息日" : "调休上班").font(.system(size: 12, weight: .medium)).foregroundStyle(mark.kind == .rest ? Palette.accent : Palette.supportingText)
                    Text(mark.name).font(.system(size: 10)).foregroundStyle(Palette.supportingText)
                }
            } else if let festival = CalendarEngine.festival(model.selectedDate) {
                Text(festival).font(.system(size: 12, weight: .medium)).foregroundStyle(Palette.accent)
            }
        }
        .frame(height: 53)
        .accessibilityElement(children: .combine)
        .overlay(alignment: .bottomTrailing) {
            if !model.holidays.hasSchedule(for: model.selectedDate) {
                Text("本年调休未收录").font(.system(size: 9)).foregroundStyle(Palette.supportingText)
            }
        }
    }

    private var seasonLine: some View {
        Group {
            if let term = model.solarTerms.next(onOrAfter: model.selectedDate) {
                let days = CalendarEngine.gregorian.dateComponents([.day], from: CalendarEngine.gregorian.startOfDay(for: model.selectedDate), to: CalendarEngine.gregorian.startOfDay(for: term.date)).day ?? 0
                HStack(spacing: 8) {
                    Image(systemName: "leaf").foregroundStyle(Palette.jade)
                    Text(term.name).fontWeight(.medium)
                    Text(CalendarEngine.format(term.date, "M月d日")).foregroundStyle(Palette.supportingText)
                    Spacer()
                    Text(days == 0 ? "今日节气" : "\(days)天后").foregroundStyle(Palette.supportingText)
                }
                .font(.system(size: 11))
                .padding(.horizontal, 12).padding(.vertical, 10)
                .background(Palette.jade.opacity(0.07), in: RoundedRectangle(cornerRadius: 10))
            }
        }
    }

    private var weatherLine: some View {
        HStack(spacing: 8) {
            if let reading = weather.reading {
                Image(systemName: reading.symbol).foregroundStyle(Palette.supportingText)
                Text("\(reading.city.name)  \(Int(reading.temperature.rounded()))°  \(reading.description)")
                Spacer()
                Text(weather.error == nil ? CalendarEngine.format(reading.receivedAt, "HH:mm 更新") : "更新失败 · 缓存").foregroundStyle(Palette.supportingText).font(.system(size: 10))
            } else {
                Image(systemName: "cloud")
                Text(weather.isLoading ? "正在获取天气…" : (weather.error ?? "天气未加载")).foregroundStyle(Palette.supportingText)
                Spacer()
            }
            Button { weather.update(enabled: model.weatherEnabled, cityID: model.weatherCity, force: true) } label: { Image(systemName: "arrow.clockwise") }
                .buttonStyle(.plain).disabled(weather.isLoading).help("刷新天气").accessibilityLabel("刷新天气")
        }.font(.system(size: 11)).padding(.horizontal, 3)
    }

    private func navigate(_ amount: Int) {
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.16)) { model.moveMonth(amount) }
    }
}

private struct DayCell: View {
    let date: Date
    let model: AppModel
    @State private var hovering = false
    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.colorScheme) private var colorScheme
    private var selected: Bool { CalendarEngine.sameDay(date, model.selectedDate) }
    private var today: Bool { CalendarEngine.sameDay(date, model.now) }
    private var inMonth: Bool { CalendarEngine.sameMonth(date, model.displayedMonth) }
    private var mark: HolidayMark? { model.holidays.mark(on: date) }
    private var accentDay: Bool { mark?.kind == .rest || (CalendarEngine.gregorian.isDateInWeekend(date) && mark?.kind != .work) }

    var body: some View {
        Button { model.select(date) } label: {
            VStack(spacing: 3) {
                Text(CalendarEngine.format(date, "d"))
                    .font(.system(size: 18, weight: today || selected ? .semibold : (colorScheme == .dark ? .medium : .regular), design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(selected ? Color.white : (accentDay || today ? Palette.accent : .primary))
                Text(model.subtitle(for: date))
                    .font(.system(size: 10, weight: colorScheme == .dark ? .medium : .regular))
                    .foregroundStyle(selected ? Color.white.opacity(0.9) : (model.solarTerms.name(on: date) != nil ? Palette.jade : (CalendarEngine.festival(date) != nil ? Palette.accent : Palette.supportingText)))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity).frame(height: 48)
            .background {
                RoundedRectangle(cornerRadius: 10)
                    .fill(selected ? Palette.selection : (hovering ? Color.primary.opacity(0.07) : (mark?.kind == .rest && inMonth ? Palette.accent.opacity(0.055) : .clear)))
            }
            .overlay {
                if today && !selected { RoundedRectangle(cornerRadius: 10).strokeBorder(Palette.accent.opacity(0.65), lineWidth: 1) }
            }
            .overlay(alignment: .topTrailing) {
                if let mark {
                    Text(mark.symbol).font(.system(size: 7, weight: .semibold))
                        .foregroundStyle(selected ? Color.white.opacity(0.9) : (mark.kind == .rest ? Palette.accent : Palette.supportingText))
                        .padding(.top, 3).padding(.trailing, 4)
                }
            }
            .contentShape(RoundedRectangle(cornerRadius: 10))
            .opacity(inMonth ? 1 : (contrast == .increased ? 0.78 : (colorScheme == .dark ? 0.62 : 0.44)))
        }
        .buttonStyle(.plain)
        .disabled(!CalendarEngine.isSupported(date))
        .onHover { hovering = $0 }
        .accessibilityLabel(model.accessibilityLabel(for: date))
        .accessibilityAddTraits(selected ? .isSelected : [])
        .help(model.accessibilityLabel(for: date))
    }
}

private struct MonthJumpView: View {
    @Bindable var model: AppModel
    @State private var yearText = ""
    @State private var year = 2026
    private var validYear: Int? { Int(yearText).flatMap { CalendarEngine.supportedYears.contains($0) ? $0 : nil } }
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("跳转年月").font(.headline)
                Spacer()
                Button("完成") { model.showingJump = false }.buttonStyle(.plain).foregroundStyle(.secondary)
            }
            HStack {
                TextField("1901–2100", text: $yearText).textFieldStyle(.roundedBorder).frame(width: 95)
                    .onSubmit { if let y = validYear { year = y } }
                    .onChange(of: yearText) { _, _ in if let y = validYear { year = y } }
                    .accessibilityLabel("年份，1901至2100")
                Text("年").foregroundStyle(.secondary)
                Spacer()
                Stepper("年份", value: $year, in: CalendarEngine.supportedYears).labelsHidden()
                    .onChange(of: year) { _, value in yearText = String(value) }
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 10) {
                ForEach(1...12, id: \.self) { month in
                    Button("\(month)月") {
                        guard let value = validYear else { return }
                        model.select(CalendarEngine.date(value, month, 1))
                        model.showingJump = false
                    }.frame(maxWidth: .infinity).buttonStyle(.bordered).disabled(validYear == nil)
                }
            }
            Text(validYear == nil ? "请输入 1901–2100 之间的年份" : "公历 · 中国标准时间 UTC+8")
                .font(.caption).foregroundStyle(.secondary)
        }.padding(20).frame(width: 290)
            .onAppear { year = model.year; yearText = String(year) }
    }
}

private struct HolidayListView: View {
    @Bindable var model: AppModel
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text("\(String(model.year)) · 中国节假日").font(.title3.weight(.semibold))
                    Text("中国大陆放假与调休安排").font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Button("完成") { model.showingHolidays = false }.keyboardShortcut(.cancelAction)
            }
            if let schedule = model.holidays.schedule(for: model.year) {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(schedule.periods) { period in
                            Button {
                                model.select(period.startDate)
                                model.showingHolidays = false
                            } label: {
                                HStack(alignment: .top) {
                                    VStack(alignment: .leading, spacing: 5) {
                                        Text(period.name).font(.system(size: 14, weight: .medium))
                                        Text("\(CalendarEngine.format(period.startDate, "M月d日")) — \(CalendarEngine.format(period.endDate, "M月d日"))").foregroundStyle(.secondary)
                                        if !period.workdays.isEmpty {
                                            Text("补班：" + period.workdays.compactMap { CalendarEngine.date(from: $0) }.map { CalendarEngine.format($0, "M/d") }.joined(separator: "、"))
                                                .font(.system(size: 10)).foregroundStyle(.secondary)
                                        }
                                    }
                                    Spacer()
                                    Text("\(period.dayCount)天").font(.system(size: 12, weight: .medium)).foregroundStyle(Palette.accent)
                                }.font(.system(size: 12)).padding(.vertical, 13).contentShape(Rectangle())
                            }.buttonStyle(.plain)
                            Divider()
                        }
                    }
                }
                Link("国务院办公厅 · \(schedule.document)", destination: URL(string: schedule.source)!)
                    .font(.system(size: 10)).foregroundStyle(.secondary)
            } else {
                ContentUnavailableView("本年调休数据未收录", systemImage: "calendar.badge.exclamationmark", description: Text("传统节日和农历仍可查看。\n休／班安排仅在收录官方通知后显示。\n当前已收录 2025、2026 年。"))
            }
        }.padding(24).frame(width: 390, height: 470).tint(Palette.accent)
    }
}
