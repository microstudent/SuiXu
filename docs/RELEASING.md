# Releasing · 发布指南

## 简体中文

### 发布前

1. 确认 `main` 的 CI 通过，工作区干净，双语 README、数据范围和 `CHANGELOG.md` 一致。
2. 更新 `Resources/Info.plist` 中的 `CFBundleShortVersionString`（语义版本，如 `1.1.0`）和递增的 `CFBundleVersion`。关于页面从包内版本读取。
3. 运行 `swift test` 和 `./scripts/package.sh`。输出为 `dist/SuiXu-<版本>-macos-<架构>.zip` 与 `dist/SHA256SUMS`。
4. 从 ZIP 解压后启动应用，检查数据资源、菜单栏、深浅色，以及“打开设置显示 Dock、关闭设置隐藏 Dock”。确认所有来源声明仍在应用包内。
5. 若更新年度调休，核对正式通知和边界测试；若更新节气，检查全部年份各 24 项及来源差异。

### 签名与分发

构建脚本只提供 ad-hoc 签名。当前仓库不配置 Developer ID、App Store 发布、自动更新或公证密钥。不要将证书、私钥、App Store Connect 凭据提交进仓库。

面向其他 Mac 的正式分发，应由维护者配置自己的 Developer ID 签名、Hardened Runtime、Apple 公证与 stapling，并在全新 Mac 上验证下载后的 Gatekeeper 行为。未完成这些步骤时，必须在发布说明里明确标记“ad-hoc 签名，未公证”；不要把签名校验通过写成 Apple 公证通过。

第三方数据的许可独立于源码 MIT。特别是天文台网站资料和免费天气 API 的商业使用限制，见 [THIRD_PARTY_NOTICES](../THIRD_PARTY_NOTICES.md)。

### GitHub 草稿发布

推送与应用版本匹配的 `vMAJOR.MINOR.PATCH` 标签，会触发 `.github/workflows/release.yml`：重新测试、打包并创建 **草稿 Release**，不会自动公开发布。

```sh
# 先确认对应版本已审查、合并且 CI 通过，再执行：
git tag -a v1.1.0 -m "SuiXu 1.1.0"
git push origin v1.1.0
```

标签示例不意味着该版本已经发布。打开草稿后补充中英变更说明、验证范围和签名状态，再由维护者点击发布。工作流只上传当前 arm64 构建；不要将其描述为 Universal 或 Intel 已验证版本。

若工作流在创建草稿之前失败，修复后重跑失败任务；如果草稿已经存在，不要重复创建标签，直接检查已有草稿与资产。下载后可用 `shasum -a 256 -c SHA256SUMS` 验证文件完整性。

## English

Before releasing, require a clean checkout and passing CI on `main`. Align both READMEs, data coverage, and the changelog. Update `CFBundleShortVersionString` and increment `CFBundleVersion` in `Resources/Info.plist`; the About view reads the bundled version.

Run `swift test` and `./scripts/package.sh`. The output is `dist/SuiXu-<version>-macos-<architecture>.zip` plus `dist/SHA256SUMS`. Extract the archive and smoke-test the bundled resources, menu bar, both appearances, and Settings-driven Dock visibility. Preserve the bundled legal notices. Verify official sources and boundary tests for calendar-data changes.

The build uses **ad-hoc signing only**. Developer ID signing, Hardened Runtime, Apple notarization/stapling, App Store distribution, and automatic updates are not configured. A maintainer must supply their own signing setup and test Gatekeeper behavior on a clean Mac before claiming notarized distribution. Never commit signing keys or service credentials. If distributing without notarization, state that limitation explicitly.

Third-party data and service terms are separate from the MIT source license; review [THIRD_PARTY_NOTICES](../THIRD_PARTY_NOTICES.md), including commercial-use restrictions.

After review and successful CI, pushing an annotated `vMAJOR.MINOR.PATCH` tag matching the app version triggers the release workflow. It runs tests, packages an arm64 build, and creates a **draft**, not a public release. The commands above are an example, not evidence of an existing release. Review the draft, add bilingual changes and verification/signing details, and publish manually. Do not describe the arm64 asset as Universal or Intel-verified.

Retry failed jobs only if no draft was created; otherwise inspect the existing draft and assets instead of recreating the tag. Users can verify downloaded files with `shasum -a 256 -c SHA256SUMS`.
