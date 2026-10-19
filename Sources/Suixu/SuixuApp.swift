import AppKit
import SwiftUI
import SuixuCore

@main
struct SuixuApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    var body: some Scene {
        Settings { EmptyView() }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate, NSToolbarDelegate, NSWindowDelegate {
    private let model = AppModel()
    private let weather = WeatherModel()
    private var statusItem: NSStatusItem!
    private let popover = NSPopover()
    private var settingsWindow: NSWindow?
    private var timer: Timer?
    private var keyMonitor: Any?
    private var observers: [NSObjectProtocol] = []
    private var appearanceObservation: NSKeyValueObservation?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        NSApp.appearance = model.appearance.native
        configureMenus()
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.target = self
            button.action = #selector(statusClicked)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            button.font = .monospacedDigitSystemFont(ofSize: 13, weight: .regular)
            button.imagePosition = .imageLeading
            button.setAccessibilityLabel("岁序万年历")
        }
        popover.behavior = .transient
        popover.animates = !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        popover.delegate = self
        popover.contentViewController = NSHostingController(rootView: CalendarView(model: model, weather: weather))
        // A status-item window can have a wallpaper-dependent appearance. Calendar content
        // follows the app/system appearance, rather than inheriting that menu-bar contrast.
        appearanceObservation = NSApp.observe(\.effectiveAppearance, options: [.initial, .new]) { [weak self] _, _ in
            Task { @MainActor in self?.popover.appearance = NSApp.effectiveAppearance }
        }
        model.onMenuChanged = { [weak self] in self?.updateStatus() }
        model.onAppearanceChanged = { [weak self] in
            guard let self else { return }
            NSApp.appearance = self.model.appearance.native
            self.popover.appearance = NSApp.effectiveAppearance
        }
        model.onPinChanged = { [weak self] in
            guard let self else { return }
            self.popover.behavior = self.model.pinned ? .applicationDefined : .transient
        }
        model.onWeatherChanged = { [weak self] in self?.updateWeather() }
        model.openSettings = { [weak self] in self?.showSettings() }
        model.closePopover = { [weak self] in self?.popover.performClose(nil) }
        updateStatus()
        scheduleClock()
        observeWake()
        installKeyboardHandling()

        // An explicit launch opens the calendar; login launches stay unobtrusive.
        let launchedAtLogin = NSAppleEventManager.shared().currentAppleEvent?.paramDescriptor(forKeyword: keyAEPropData)?.enumCodeValue == keyAELaunchedAsLogInItem
        if !launchedAtLogin {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in self?.showCalendar() }
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showCalendar()
        return true
    }

    private func configureMenus() {
        let menu = NSMenu()
        let appItem = NSMenuItem()
        let appMenu = NSMenu(title: "岁序")
        let settings = NSMenuItem(title: "岁序设置…", action: #selector(showSettings), keyEquivalent: ",")
        settings.target = self
        appMenu.addItem(settings)
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "退出岁序", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appItem.submenu = appMenu
        menu.addItem(appItem)
        let editItem = NSMenuItem()
        let edit = NSMenu(title: "编辑")
        edit.addItem(withTitle: "剪切", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        edit.addItem(withTitle: "复制", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        edit.addItem(withTitle: "粘贴", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        edit.addItem(withTitle: "全选", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        editItem.submenu = edit
        menu.addItem(editItem)
        NSApp.mainMenu = menu
    }

    private func updateStatus() {
        guard let button = statusItem?.button else { return }
        button.image = nil
        button.title = model.menuTitle
        button.toolTip = "岁序 · \(CalendarEngine.format(model.now, "yyyy年M月d日 EEEE")) · \(CalendarEngine.lunar(model.now).fullName)\n点击打开日历，右键打开菜单"
    }

    @objc private func statusClicked() {
        if NSApp.currentEvent?.type == .rightMouseUp {
            let menu = NSMenu()
            let open = NSMenuItem(title: "打开岁序", action: #selector(showCalendar), keyEquivalent: "")
            open.target = self
            menu.addItem(open)
            let settings = NSMenuItem(title: "设置…", action: #selector(showSettings), keyEquivalent: ",")
            settings.target = self
            menu.addItem(settings)
            menu.addItem(.separator())
            menu.addItem(withTitle: "退出岁序", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
            statusItem.menu = menu
            statusItem.button?.performClick(nil)
            statusItem.menu = nil
        } else if popover.isShown {
            popover.performClose(nil)
        } else { showCalendar() }
    }

    @objc private func showCalendar() {
        guard let button = statusItem.button else { return }
        model.refreshClock()
        popover.appearance = NSApp.effectiveAppearance
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        NSApp.activate(ignoringOtherApps: true)
        popover.contentViewController?.view.window?.makeKey()
        updateWeather()
    }

    @objc private func showSettings() {
        popover.performClose(nil)
        // Only the settings window participates in Dock / app switching.
        NSApp.setActivationPolicy(.regular)
        if settingsWindow == nil {
            let window = NSWindow(contentViewController: NSHostingController(rootView: SettingsView(model: model)))
            window.delegate = self
            window.title = "岁序设置"
            window.styleMask = [.titled, .closable, .miniaturizable]
            let toolbar = NSToolbar(identifier: "SuixuSettings")
            toolbar.delegate = self
            toolbar.displayMode = .iconAndLabel
            toolbar.allowsUserCustomization = false
            toolbar.selectedItemIdentifier = NSToolbarItem.Identifier(model.settingsSection.rawValue)
            window.toolbar = toolbar
            window.toolbarStyle = .preference
            window.isReleasedWhenClosed = false
            window.center()
            settingsWindow = window
        }
        NSApp.activate(ignoringOtherApps: true)
        settingsWindow?.makeKeyAndOrderFront(nil)
    }

    func windowWillClose(_ notification: Notification) {
        guard let window = notification.object as? NSWindow, window === settingsWindow else { return }
        NSApp.setActivationPolicy(.accessory)
    }

    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        SettingsSection.allCases.map { NSToolbarItem.Identifier($0.rawValue) }
    }
    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] { toolbarDefaultItemIdentifiers(toolbar) }
    func toolbarSelectableItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] { toolbarDefaultItemIdentifiers(toolbar) }
    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier identifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        guard let section = SettingsSection(rawValue: identifier.rawValue) else { return nil }
        let item = NSToolbarItem(itemIdentifier: identifier)
        item.label = section.title
        item.image = NSImage(systemSymbolName: section.symbol, accessibilityDescription: section.title)
        item.target = self
        item.action = #selector(selectSettingsSection(_:))
        return item
    }
    @objc private func selectSettingsSection(_ item: NSToolbarItem) {
        guard let section = SettingsSection(rawValue: item.itemIdentifier.rawValue) else { return }
        model.settingsSection = section
        settingsWindow?.toolbar?.selectedItemIdentifier = item.itemIdentifier
    }

    private func updateWeather() {
        weather.update(enabled: model.weatherEnabled, cityID: model.weatherCity)
    }

    private func scheduleClock() {
        timer?.invalidate()
        let interval = 60 - Date().timeIntervalSince1970.truncatingRemainder(dividingBy: 60)
        let timer = Timer(fire: Date().addingTimeInterval(interval), interval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.model.refreshClock() }
        }
        timer.tolerance = 1
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    private func observeWake() {
        observers.append(NSWorkspace.shared.notificationCenter.addObserver(forName: NSWorkspace.didWakeNotification, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in
                self?.model.refreshClock()
                self?.scheduleClock()
                if self?.popover.isShown == true { self?.updateWeather() }
            }
        })
        observers.append(NotificationCenter.default.addObserver(forName: .NSSystemClockDidChange, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in self?.model.refreshClock(); self?.scheduleClock() }
        })
    }

    private func installKeyboardHandling() {
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            let handled = MainActor.assumeIsolated {
                guard let self else { return false }
                let command = event.modifierFlags.contains(.command)
                #if DEBUG
                // App-only visual QA; does not change the user's system appearance.
                if command && event.modifierFlags.contains(.shift) && event.charactersIgnoringModifiers?.lowercased() == "d" {
                    let dark = NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
                    NSApp.appearance = NSAppearance(named: dark ? .aqua : .darkAqua)
                    self.popover.appearance = NSApp.effectiveAppearance
                    return true
                }
                #endif
                if command && event.charactersIgnoringModifiers == "," { self.showSettings(); return true }
                if command && event.charactersIgnoringModifiers == "w", self.settingsWindow?.isKeyWindow == true {
                    self.settingsWindow?.close(); return true
                }
                guard self.popover.isShown, !self.model.showingJump, !self.model.showingHolidays,
                      event.window == self.popover.contentViewController?.view.window else { return false }
                switch event.keyCode {
                case 53: self.popover.performClose(nil)
                case 49: self.model.today()
                case 123: command ? self.model.moveMonth(-1) : self.model.select(CalendarEngine.addingDays(-1, to: self.model.selectedDate))
                case 124: command ? self.model.moveMonth(1) : self.model.select(CalendarEngine.addingDays(1, to: self.model.selectedDate))
                case 125: self.model.select(CalendarEngine.addingDays(7, to: self.model.selectedDate))
                case 126: self.model.select(CalendarEngine.addingDays(-7, to: self.model.selectedDate))
                default: return false
                }
                return true
            }
            return handled ? nil : event
        }
    }
}
