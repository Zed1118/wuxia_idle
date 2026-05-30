# Phase A·B 段 心法面板 视觉切片 spec

> 2026-05-31 · 出版美术第二刀 · 配套 `PUBLISHING_ART_PASS_1_0.md` / 样图 03 境界突破
> 主菜单切片已收口(全屏 bg+题字+双列木牌+锁印 · Codex 验 6PASS/2WARN→双列+木牌迭代闭环 · Mac 本地视觉自验 PASS)

## 目标
心法面板(`technique_panel_screen.dart` 398 行)从"数值列表感"→"秘籍/卷轴感"(样图 03:宣纸面板 + 阶位 + 段位进度 + 打坐/内丹)。

## 可复用素材(已核实存在 assets/ui/)
- `paper_bg.png` ✅ 宣纸底 · `scroll_vertical/horizontal.png` 卷轴框 · `seal_red.png` 绛红印章 · `ink_divider.png` 墨分隔 · `meditation_icon.png` 打坐(主修 hero)· `lotus_icon.png`
- `assets/techniques/` **空** → 7 阶心法卷轴 cover = greenfield(B2 待美术)

## 3 决议(默认拍板)
- B1 宣纸底:用现有 `paper_bg.png` ✅
- 题字/书法:占位字体(同主菜单,授权后替)
- B4 主修 hero:用 `meditation_icon.png` 占位打坐,非纯 greenfield

## 任务拆解
| # | 任务 | 涉及 | 素材 | 风险 |
|---|------|------|------|------|
| B1 | 抽 `WuxiaPaperPanel`(paper_bg 宣纸底 + 墨边)共用组件,包面板 body | 新 `shared/widgets/` + technique_panel | paper_bg ✅ | 低(加新文件) |
| B2 | tier 卷轴 cover(代码已 wire,缺图) | (就绪) | 7 阶 cover greenfield | — |
| B3 | 心法 tile → 秘籍质感(ink_divider 分隔 + cultivationLayer 印章 badge) | technique_panel | seal_red/ink_divider ✅ | 中 |
| B4 | 主修 hero 区(meditation_icon 打坐 + 内丹点缀=§0.6 关键节点克制彩光) | technique_panel | meditation_icon ✅ | 中 |
| B5 | 段位进度(9 层阶梯/分段 + 金徽章,样图 03 Early/Middle/Late 体例) | technique_panel | — | 中 |

## 顺序
B1(抽 WuxiaPaperPanel · 安全先行,同 A1 体例)→ B3/B4/B5(同屏整合)→ B2(等 cover 出图)

## 验收
Mac 本地 `flutter run -d macos` + `screencapture` 自验 · 对照样图 03 秘籍感 · 守 1606 测 / 0 analyze · widget 测纪律(errorBuilder / viewport)

## 工作量(代码侧 · 美术另算)
B1 ~半天 · B3/B4/B5 整合 ~1 天 → 合计 ~1-2 天 · 卡点 B2 7 阶 cover 美术(可占位先行)
