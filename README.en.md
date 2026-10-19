<div align="center">
  <img src="Resources/AppIcon.iconset/icon_128x128@2x.png" width="96" alt="SuiXu app icon">
  <h1>SuiXu · 岁序</h1>
  <p>A quiet, native Chinese calendar for the macOS menu bar.</p>
  <p><a href="README.md">简体中文</a> · <strong>English</strong></p>
  <p>
    <a href="https://github.com/microstudent/SuiXu/actions/workflows/ci.yml"><img src="https://github.com/microstudent/SuiXu/actions/workflows/ci.yml/badge.svg" alt="CI"></a>
    <img src="https://img.shields.io/badge/macOS-26%2B-black" alt="macOS 26 or later">
    <img src="https://img.shields.io/badge/Swift-6-orange" alt="Swift 6">
    <a href="LICENSE"><img src="https://img.shields.io/badge/code_license-MIT-blue" alt="MIT code license"></a>
  </p>
</div>

SuiXu brings Gregorian dates, the Chinese lunar calendar, solar terms, and mainland China's holiday arrangements into a compact popover. Built with SwiftUI and AppKit, it has no third-party runtime dependencies, ads, accounts, or usage analytics. **The app interface is currently in Simplified Chinese; project documentation is available in Chinese and English.**

<p align="center">
  <img src="docs/calendar-light.png" width="340" alt="SuiXu calendar in light appearance">
  <img src="docs/calendar-dark.png" width="340" alt="SuiXu calendar in dark appearance">
</p>

## Features

- **Chinese calendar:** Gregorian and lunar dates, the sexagenary cycle, zodiac animals, common traditional festivals, and offline solar terms for 1901–2100.
- **Holidays and make-up workdays:** official mainland China schedules for 2025 and 2026, separate rest/work markers, and annual lists. Missing years are clearly marked; schedules are never guessed.
- **Compact month view:** five or six rows as needed, month/year navigation, keyboard shortcuts, jump to today, and a pin to keep the popover open.
- **Menu bar date:** date with weekday, short date, or lunar date; optional 24-hour time.
- **Native appearance:** system, light, and dark modes; Liquid Glass navigation and a native blurred content surface, with reduced-transparency and increased-contrast support.
- **Quiet operation:** normally a menu bar app; a Dock icon appears while Settings is open and disappears when Settings closes. Optional launch at login.
- **Optional weather:** off by default, with 12 manually selected cities and no location permission. Open-Meteo requests are made on demand and cached for 30 minutes.

## Requirements

| Item | Requirement |
| --- | --- |
| Operating system | macOS 26.0 or later |
| Build tools | Full Xcode 26 or later; Command Line Tools alone are insufficient |
| Architecture | Verified on Apple Silicon (arm64); builds target the host architecture. Intel has not been verified |
| Network | Calendar works offline; weather and explicit source-data refreshes require a connection |

## Install and run

Building from source is currently recommended. Downloadable builds exist only when assets have actually been published under [Releases](https://github.com/microstudent/SuiXu/releases); no compiled `.app` is committed to the repository.

```sh
git clone https://github.com/microstudent/SuiXu.git
cd SuiXu
./scripts/build.sh
open dist/岁序.app
```

Drag `dist/岁序.app` into Applications, quit any instance running from the build directory, then launch the installed copy. You can subsequently find SuiXu through Spotlight or Applications. Quit the old version before replacing it during updates.

Local builds use **ad-hoc signing**. They are not Developer ID signed or notarized by Apple. A successful build does not imply notarized distribution to other Macs; see the [release guide](docs/RELEASING.md).

## Usage

Click the menu bar date to open the calendar, or right-click for a quick menu. Select a day for details and click the month heading to choose a month or year. The top-right “…” menu contains annual holidays, Settings, and Quit.

| Shortcut | Action |
| --- | --- |
| Space | Today |
| ← / →, ↑ / ↓ | Previous/next day, previous/next week |
| ⌘← / ⌘→ | Previous/next month |
| ⌘, | Open Settings |
| Esc | Close the popover or current panel |
| ⌘W | Close Settings |
| ⌘Q | Quit SuiXu |

Date navigation shortcuts apply while the calendar popover is open, outside the month picker and annual holiday list. macOS manages menu bar ordering; hold ⌘ and drag to reposition the item. SuiXu does not force itself to the far right.

## Data and privacy

- Chinese calendar dates always use **UTC+8**, independent of travel or the system time zone.
- Foundation supplies lunar conversion. The 4,800 bundled solar-term dates are extracted from Hong Kong Observatory tables and require no runtime downloads.
- Official holiday schedules currently cover **2025 and 2026** and are updated with app versions.
- When weather is off, the app makes no weather requests. Enabling it sends the selected city's public coordinates to Open-Meteo; the service also receives the IP address needed for the connection. The app does not request precise location, upload calendar selections, or include an analytics SDK.
- Weather is a model estimate, and future astronomical dates may be revised by their source. See [data provenance and maintenance](docs/DATA.md) for details and coverage.

## Development and validation

```sh
swift test                    # Calendar, data, and app-state tests
./scripts/build.sh debug       # Debug app
./scripts/build.sh             # Release app and signature verification
./scripts/package.sh           # Versioned ZIP and SHA-256 checksum file
```

You can also open `Package.swift` in Xcode. The bundle script includes resources and the app icon; use the resulting `.app` to validate menu bar and login behavior. Debug builds include an app-only `⌘⇧D` appearance toggle; release builds do not.

CI runs tests and Release packaging on pushes and pull requests. GitHub Actions are pinned to full commit hashes and checked for updates by Dependabot. Tests cover 200 years of month boundaries, both week-start layouts, lunar new year, leap months, UTC+8 midnight, solar terms, and official holiday schedules. See the [validation record](docs/VALIDATION.md) for manual checks and known verification limits.

```text
Sources/Suixu/          SwiftUI / AppKit app, settings, weather
Sources/SuixuCore/      Calendar logic and offline data
Tests/                 Swift Testing tests
Resources/             App metadata and original icon
scripts/               Build, packaging, icon, and data maintenance
.github/               CI, release workflow, and collaboration templates
docs/                  Sources, release instructions, and real app screenshots
```

## Contributing

[Issues](https://github.com/microstudent/SuiXu/issues) and pull requests in Chinese or English are welcome. Read [CONTRIBUTING](CONTRIBUTING.md) before starting. Report security concerns privately as described in [SECURITY](SECURITY.md). Changes are tracked in the [changelog](CHANGELOG.md).

## License and acknowledgements

Original code, documentation, and app artwork are licensed under [MIT](LICENSE), copyright leavesgeek and the respective contributors. **Third-party data and services are not relicensed under MIT.** Hong Kong Observatory material and Open-Meteo are subject to their own terms; review them before commercial redistribution. See [third-party notices](THIRD_PARTY_NOTICES.md).

Thanks to the Hong Kong Observatory, the General Office of the State Council, and Open-Meteo for their public calendar information, holiday notices, and weather service. SuiXu is an independent project, with no affiliation with or endorsement by those organizations or Apple.
