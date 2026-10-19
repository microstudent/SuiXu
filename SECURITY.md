# Security policy · 安全政策

## 报告漏洞 / Reporting a vulnerability

请勿在公开 Issue 中发布尚未修复漏洞的利用细节、访问令牌或个人资料。

通过 GitHub 的 [私密漏洞报告入口](https://github.com/microstudent/SuiXu/security/advisories/new) 联系维护者；若该入口不可用，请发送邮件至 **leavesgeek@gmail.com**，主题注明 `SuiXu security`。

Please do not publish exploit details, credentials, or personal information in public issues before a fix is available. Use [GitHub private vulnerability reporting](https://github.com/microstudent/SuiXu/security/advisories/new), or email **leavesgeek@gmail.com** with the subject `SuiXu security` if that feature is unavailable.

请包含 / Include:

- 受影响版本、macOS 版本 / Affected version and macOS version.
- 最小复现步骤与影响 / Minimal reproduction and impact.
- 可用的缓解措施 / Any known mitigation.

维护者会尽力确认、调查并协调修复；个人维护项目不承诺固定响应时间。目前安全修复面向最新 `main` 和最新发布版本，不维护旧版本分支。

The maintainer will make a best effort to acknowledge, investigate, and coordinate a fix. This independently maintained project does not promise a response-time SLA. Security fixes target current `main` and the latest release, with no separate maintenance branches for older versions.

## 运行边界 / Runtime boundaries

日历与内置数据离线运行。天气默认关闭，开启后使用 HTTPS 访问 Open-Meteo。项目不包含遥测、自动更新器或远程代码执行功能；数据刷新脚本只供开发者显式运行。

The calendar and bundled data work offline. Optional weather uses HTTPS to Open-Meteo and is disabled by default. There is no telemetry, auto-updater, or remote-code execution feature. Data-refresh scripts are for explicit developer use only.

当前构建采用 ad-hoc 签名，未经过 Developer ID 签名或 Apple 公证。发布安全边界见 [RELEASING](docs/RELEASING.md)。

Current builds use ad-hoc signing and are not Developer ID signed or Apple-notarized. See [RELEASING](docs/RELEASING.md) for distribution requirements.
