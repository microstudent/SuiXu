# 数据来源与维护

整理与核验日期：2026-10-19。

## 中国大陆放假与调休

原始文件：

- [国务院办公厅关于2025年部分节假日安排的通知](https://www.gov.cn/zhengce/zhengceku/202411/content_6986383.htm)，国办发明电〔2024〕12号。[国家林业和草原局转载](https://www.forestry.gov.cn/c/www/szxx/594663.jhtml)用于核对全文。
- [国务院办公厅关于2026年部分节假日安排的通知](https://www.gov.cn/zhengce/content/202511/content_7047090.htm)，国办发明电〔2025〕7号。[陆丰市政府转载](https://www.lufengshi.gov.cn/swlfsjj/gkmlpt/content/1/1199/post_1199727.html)用于核对全文。

`Sources/SuixuCore/Resources/holidays.json` 记录年度、官方来源链接、文件编号、每段假期的起止日期与补班日期。程序将区间展开为「休」，将补班标为「班」。常规周末不标「休」，传统节日不自动转换成放假。

2026 年校验总数：33 个安排中的放假日、6 个补班日。2025 年为 28 个放假日、5 个补班日。未收录的年度为未知，不能用通用周末规则推算补班。

更新下一年度：核对官方通知，添加一条年度记录及对应边界测试，运行 `swift test`，重新构建并分发。当前无后台数据更新、远程配置或自动推测。

## 节气

数据来源：[香港天文台公历与农历对照表](https://www.hko.gov.hk/tc/gts/time/conversion.htm)。本项目仅抽取事实性的公历日期与节气名称，繁体名称转换为简体。

示例原始数据：[2026 年文字表](https://www.hko.gov.hk/tc/gts/time/calendar/text/files/T2026c.txt)、[2026 年 PDF](https://www.hko.gov.hk/tc/gts/time/calendar/pdf/files/2026.pdf)。

`Sources/SuixuCore/Resources/solar-terms.json` 内置 1901–2100 年共 4,800 条记录。维护脚本每次最多 4 个并发请求，失败重试，每年必须恰有 24 个互不重复的节气名称，全部成功后才原子替换资源。维护操作需联网；日常启动、构建与使用无需下载这些数据。

```sh
python3 scripts/update_solar_terms.py
swift test
```

天文台说明：部分远期新月及节气接近午夜，预测修订可能带来一日差异。农历转换由 macOS Foundation 提供，节气日使用上述离线表；需要对远期天文历法作专业用途时，应核对当年的权威历书。

## 天气

来源：[Open-Meteo Forecast API](https://open-meteo.com/en/docs)，参数仅包括所选城市公共坐标、温度、天气代码、昼夜状态和 Asia/Shanghai 时区。无精确定位、账户或使用行为上传。数据署名及链接保留在设置中。

Open-Meteo 的免费 API 面向非商业用途并有请求额度；商业分发前应按其当时的[使用条款](https://open-meteo.com/en/terms)选择服务方案。天气失败不影响离线历法功能。

## 系统设计参考

- [Apple HIG：Materials](https://developer.apple.com/design/human-interface-guidelines/materials)
- [Apple HIG：The menu bar](https://developer.apple.com/design/human-interface-guidelines/the-menu-bar)
- [Apple：Adopting Liquid Glass](https://developer.apple.com/documentation/technologyoverviews/adopting-liquid-glass)
- [SwiftUI glassEffect](https://developer.apple.com/documentation/swiftui/view/glasseffect(_:in:))

应用使用公开 SwiftUI / AppKit API，不以自绘模糊或网页 CSS 模拟 Liquid Glass。
