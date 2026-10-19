import AppKit
import ServiceManagement
import SwiftUI
import SuixuCore

struct SettingsView: View {
    @Bindable var model: AppModel
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled
    @State private var loginError: String?

    var body: some View {
        Group {
            switch model.settingsSection {
            case .general: general
            case .menuBar: menuBar
            case .weather: weather
            case .about: about
            }
        }
        .frame(width: 510, height: 470)
        .tint(Palette.accent)
    }

    private var general: some View {
        Form {
            Section {
                Picker("一周开始于", selection: $model.mondayFirst) {
                    Text("星期一").tag(true)
                    Text("星期日").tag(false)
                }
            } header: { Text("日历") } footer: {
                Text("中国历法固定使用中国标准时间（UTC+8），确保农历、节气和调休日期一致。")
            }
            Section {
                Picker("外观", selection: $model.appearance) {
                    ForEach(AppAppearance.allCases) { value in Text(value.title).tag(value) }
                }
            } header: { Text("显示") } footer: {
                Text("面板保留通透质感，深色外观自动加深背景，让日期更易读。尊重系统的减少透明度与增强对比度设置。")
            }
            Section {
                Toggle("登录时启动岁序", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, enabled in
                        do {
                            if enabled { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() }
                            loginError = SMAppService.mainApp.status == .requiresApproval ? "请在系统设置 → 通用 → 登录项中允许岁序。" : nil
                        } catch {
                            loginError = "无法更新登录项：\(error.localizedDescription)"
                            launchAtLogin = SMAppService.mainApp.status == .enabled
                        }
                    }
                if let loginError { Text(loginError).font(.caption).foregroundStyle(.secondary) }
            }
            Section("日历快捷键") {
                LabeledContent("回到今天", value: "空格")
                LabeledContent("选择日期", value: "← ↑ ↓ →")
                LabeledContent("切换月份", value: "⌘← / ⌘→")
                LabeledContent("打开设置 / 关闭浮层", value: "⌘, / Esc")
            }
        }.formStyle(.grouped)
    }

    private var menuBar: some View {
        VStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 12) {
                Text("菜单栏预览").font(.caption).foregroundStyle(.secondary)
                HStack(spacing: 6) {
                    Spacer()
                    Text(model.menuTitle).monospacedDigit()
                    Spacer()
                }
                .font(.system(size: 13, weight: .medium))
                .frame(height: 34).background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
            }.padding(20)
            Form {
                Section {
                    Picker("显示内容", selection: $model.menuStyle) {
                        ForEach(MenuStyle.allCases) { style in Text(style.title).tag(style) }
                    }
                    Toggle("附带时间（24 小时）", isOn: $model.showTime)
                } footer: { Text("默认仅显示日期与星期，避免重复系统时钟。按住 ⌘ 拖动菜单栏项目，可调整位置。") }
            }.formStyle(.grouped)
            Spacer(minLength: 0)
        }
    }

    private var weather: some View {
        Form {
            Section {
                Toggle("在日历底部显示天气", isOn: $model.weatherEnabled)
                Picker("城市", selection: $model.weatherCity) {
                    ForEach(WeatherCity.all) { city in Text(city.name).tag(city.id) }
                }.disabled(!model.weatherEnabled)
            } header: { Text("轻量天气") } footer: {
                Text("默认关闭。启用后，仅向 Open-Meteo 发送所选城市的公共坐标；不请求定位权限。打开日历时按需更新，缓存 30 分钟。")
            }
            Section {
                Link("天气数据：Open-Meteo", destination: URL(string: "https://open-meteo.com/")!)
                Text("天气为模型估算的当前状况，可能与实况存在差异。离线或请求失败时会明确提示，不影响日历。")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }.formStyle(.grouped)
    }

    private var about: some View {
        VStack(spacing: 13) {
            Image(systemName: "sun.horizon").font(.system(size: 36, weight: .light)).foregroundStyle(Palette.accent).padding(.top, 25)
            Text("岁序").font(.system(size: 27, weight: .medium, design: .serif))
            Text("日有序，岁有时").font(.system(size: 12)).foregroundStyle(.secondary)
            Text("\(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "开发版") · 原生 macOS 万年历").font(.caption).foregroundStyle(.secondary)
            Divider().padding(.horizontal, 45).padding(.vertical, 8)
            Text("公历与农历 1901–2100 · 节气离线可用\n中国大陆放假调休已收录 2025、2026 年")
                .font(.system(size: 12)).multilineTextAlignment(.center).lineSpacing(5)
            Link("节气日期：香港天文台", destination: URL(string: "https://www.hko.gov.hk/tc/gts/time/conversion.htm")!).font(.caption)
            HStack(spacing: 16) {
                Link("GitHub", destination: URL(string: "https://github.com/microstudent/SuiXu")!)
                Button("许可证与数据声明") {
                    if let url = Bundle.main.resourceURL?.appendingPathComponent("Legal") {
                        NSWorkspace.shared.open(url)
                    }
                }.buttonStyle(.link)
            }.font(.caption)
            Text("节假日数据随应用版本更新；未收录年份不推测调休。\n无广告，无账户，无使用行为追踪。")
                .font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center).lineSpacing(4)
            Spacer()
            Button("退出岁序") { NSApp.terminate(nil) }.buttonStyle(.bordered)
        }
    }
}
