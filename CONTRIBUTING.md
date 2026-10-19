# Contributing · 贡献指南

[简体中文](#简体中文) · [English](#english)

## 简体中文

感谢你帮助改进岁序。Issue 和 PR 可以使用中文或英文。

### 开始之前

- 先搜索已有 Issue；较大的功能或架构调整先开 Issue 讨论范围。
- 聚焦原生、轻量的中国历法工具。不要在无关改动中加入广告、追踪、账户或新的运行时依赖。
- Bug 报告请附复现步骤、预期／实际行为、macOS 与应用版本；日期错误请提供具体日期和官方来源。
- 截图、日志和补丁中不要包含密码、令牌、内部地址或无关个人信息。安全问题走 [私下报告流程](SECURITY.md)。

### 本地开发

需要完整 Xcode 26+ 与 macOS 26+。克隆仓库后运行：

```sh
swift test
./scripts/build.sh debug
open dist/岁序.app
```

历法与数据逻辑放在 `SuixuCore`；界面、AppKit 生命周期和天气放在 `Suixu`。保持现有代码风格与 `.editorconfig` 约定，使用公开 Apple API。

### 提交 PR

1. 从最新 `main` 建立主题分支，每个 PR 解决一个明确问题。
2. 为历法、持久化、网络状态等行为变更补充有意义的回归测试；单纯视觉调整提供实机截图和检查说明。
3. 运行 `swift test` 与 `./scripts/package.sh`。界面变更检查深浅色、菜单栏与设置窗口开关；不要声称未实际验证的平台通过。
4. 同步更新 `README.md`、`README.en.md` 及相关说明；用户可见变化写入 `CHANGELOG.md` 的 Unreleased。
5. 使用简明提交信息，例如 `fix: preserve selected day at month boundaries`。PR 说明问题、结果、验证和已知限制。

不提交 `.build/`、`dist/`、签名证书、密钥、用户偏好或本机路径。无需 CLA；提交的原创贡献采用项目 MIT 许可证。引入外部数据或素材时需说明来源和适用条款，不能把第三方内容直接声明为 MIT。

### 数据维护与交流

假期只依据正式通知；未知年份不猜测补班。节气刷新是显式维护操作，按 [数据说明](docs/DATA.md) 操作并检查差异。对代码和证据提出意见，尊重参与者，不接受骚扰或披露他人隐私。

## English

Thank you for improving SuiXu. Issues and pull requests may be written in Chinese or English.

### Before starting

- Search existing issues; discuss substantial features or architecture changes in an issue first.
- Keep the project a focused, native Chinese calendar. Avoid unrelated ads, tracking, accounts, and new runtime dependencies.
- For bugs, include reproduction steps, expected/actual behavior, macOS and app versions. Date corrections need a concrete date and an authoritative source.
- Remove credentials, internal URLs, and unrelated personal information from logs and screenshots. Report vulnerabilities through [SECURITY](SECURITY.md).

### Development

Use full Xcode 26+ on macOS 26+, then run the commands above. `SuixuCore` owns calendar logic and datasets; `Suixu` owns UI, AppKit lifecycle, and weather. Follow the surrounding style and `.editorconfig`, and use public Apple APIs.

### Pull requests

1. Create a focused branch from current `main` and solve one clear problem per PR.
2. Add meaningful regression coverage for calendar, persistence, and network behavior. For visual-only changes, provide app screenshots and manual checks.
3. Run `swift test` and `./scripts/package.sh`. Check light/dark appearance, the menu bar, and settings-window lifecycle for UI changes. State platform verification limits honestly.
4. Keep both READMEs and related documentation aligned; add user-visible changes under Unreleased in `CHANGELOG.md`.
5. Use concise commit messages, for example `fix: preserve selected day at month boundaries`. Explain the problem, resulting behavior, validation, and limitations in the PR.

Do not commit build output, distribution bundles, signing identities, credentials, user preferences, or local machine paths. No CLA is required; original contributions use the project's MIT license. Identify the source and terms of external data or artwork instead of relicensing them as MIT.

Holiday updates must follow official notices; never guess make-up workdays for missing years. Solar-term refreshes are explicit maintenance operations described in [DATA](docs/DATA.md). Discuss code and evidence respectfully; harassment and disclosure of others' private information are not accepted.
