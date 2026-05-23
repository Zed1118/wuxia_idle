# Codex 桌面 Pen Windows 视觉验收派单 spec(P5+ + P3 + Ch4-6 集中批)

> 日期:2026-05-24 凌晨 / 派单方:Mac Opus / 执行方:Codex 桌面 @ Pen Windows
> 目的:集中验收 P5+ 多代飞升流 + P3.1 轻功对决 + P3.2 群战守城 + Ch4-6 主线 narrative + inner_demon 7 关 6 系统的视觉层 GUI 实证
> 工具链 cheatsheet:memory `feedback_codex_pen_windows_visual_check`
> 8h overnight 流批 2/5(B.1 · 异步派单 · 不真派 · 用户起床手动执行)

## 验收范围(6 系统 14 验收点 · 优先级 P0/P1/P2)

| # | 系统 | 验收点 | 优先级 | 期望证据 |
|---|---|---|---|---|
| 1 | P5+ 多代飞升 | LineagePanel _AscensionSection 飞升按钮 enable(founder 达 wuSheng·dengFeng + 2 stage cleared + ≥1 disciple 在 active) | P0 | 截图按钮亮起 + hint 显「武圣登峰后...」 |
| 2 | P5+ AscensionScreen | _PromotedDiscipleRow 下拉显大弟子默认 + 可切换二弟子(spec Q1 player_pick) | P0 | 截图下拉打开 · 选项 ≥ 2 |
| 3 | P5+ AscensionScreen | dialog 确认 · 「门派衣钵:{弟子名}」strong 行显示(A.4 本批新增) | P0 | 截图 dialog 含接任名 + resultHighlight 色 |
| 4 | P5+ snackbar | 飞升完成 snackbar 显「飞升渡劫已成 · 已传 N 件遗物 · 你已退出江湖 · {弟子名} 接掌门派」(A.4 新增) | P0 | 截图 snackbar 含传位后缀 |
| 5 | P5+ 多代 chip | gen2 飞升后 character_panel/LineagePanel heritage 件显「3 代传承」chip(A.2 + A.3 本批新增) | P1 | 截图 chip 文字 |
| 6 | P5+ 边界 | gen1 飞升后 AscensionScreen 重开,_PromotedDiscipleRow 下拉**不显**已 promoted disciple(A.1 R5.9 红线)| P0 | 截图下拉只剩二弟子选项 |
| 7 | P3.1 轻功对决 | main_menu 第 13 按钮「轻功对决」enable · stage_light_foot_01..05 5 关可进 | P1 | 截图主菜单 + 5 关入口 |
| 8 | P3.1 stage 演出 | 5 关跨 yiLiu/jueDing 2 Tier × 3 terrain(water/rooftop/bamboo)narrative + 战斗演出 | P2 | 截图 1-2 关代表 |
| 9 | P3.2 群战守城 | main_menu 第 14 按钮「群战守城」enable · stage_mass_battle_*  关可进 | P1 | 截图主菜单 + stage 入口 |
| 10 | P3.2 群战 | 6v3 战斗布阵 UI(GDD §12.3)正确显左 6 右 3 | P2 | 截图布阵 |
| 11 | Ch4 西出阳关 | stage_04_01..05 5 关 narrative_opening / narrative_victory 加载正常(无 placeholder) | P1 | 截图章节首关 narrative reader |
| 12 | Ch5 征东 | stage_05_01..05 5 关 narrative 同上 | P1 | 截图章节首关 narrative reader |
| 13 | Ch6 飞升 | stage_06_01..05 5 关 narrative + chapter_06 prologue/epilogue 显示完整 | P1 | 截图首关 + 终关 |
| 14 | inner_demon 7 关 | InnerDemonScreen 7 关 cleared/available/locked 三态显 + entry 链路 | P1 | 截图主菜单 entry + 7 关网格 |

## fixture self-check 清单(派单前 Mac 端检查)

- [x] **P5+ A.1-A.4 已 ship**(main HEAD `4229a12`)· `listDiscipleTargets` isFounder 过滤 · 多代 chip · dialog/snackbar promoted 名
- [x] **debug seed for P5+** ✅(H 批 `f70f990` 已 ship):Phase2TestMenu 加 VC-P5+ 按钮 → `seedVisualCheckP5Plus()`(founder boost wuSheng·dengFeng + stage_inner_demon_07/stage_06_05 cleared)+ 直跳 LineagePanelScreen。Codex 跑此 seed 后「步入飞升」按钮自动 enable,90min 内可完成 P0 6 项硬证据截图
- [x] **P5+ narrative ascension_lineage_chant 已接入**(H.1 `f70f990`):AscendService.isLineageContinuation() pre-flight 判定 + AscensionScreen narrative 条件 load(gen2+ → lineage_chant · gen1 → complete)。Codex 跑 gen2 场景可拿 lineage_chant narrative 截图(需先 perform 1 次 gen1 飞升)
- [x] Ch4-6 narrative 全 25 文件齐(stage opening/victory 各 5 章 5 关 = 50 file)
- [x] inner_demon 7 关 narrative 全 21 文件齐
- [x] UI 字符串引用 `lib/shared/strings.dart`(派单 prompt 必先 grep · memory `feedback_codex_pen_windows_visual_check` §2026-05-21)

## 派单约束(硬约束)

- 不动 GDD / CLAUDE / numbers / data_schema
- 不改 lib / test 代码(发现 bug 截图 + closeout 标 WARN · 不自修)
- 不 push(只 commit 到 `docs/screenshots/` + `docs/handoff/codex_*.md`)
- 不装新包(PowerShell .NET 零依赖路线)
- **batch 体量** ≤ 10 截图/round · 14 验收点拆 2 round 跑(P0 6 项 round1 · P1+P2 8 项 round2)

## 必收硬证据 vs 能给则给

**必收 P0**(6 项):#1 #2 #3 #4 #6 #14 — 全是新功能/红线证据 · 失败必 retry
**能给则给 P1**(7 项):#5 #7 #9 #11 #12 #13 — 主菜单 + narrative 加载,占位不致命
**附加 P2**(2 项):#8 #10 — 演出层,fixture 不齐时跳过

## 起床 first-read(用户起床派 Codex 前)

1. 读本 doc(派单 spec)
2. 读 memory `feedback_codex_pen_windows_visual_check`(工具链 cheatsheet + 派单纪律)
3. 补 fixture(Phase2TestMenu 加 VC-P5+ 按钮 ~15min Mac 端)
4. SSH 派 Codex round1(P0 6 项)· 90min 预算
5. 看 round1 截图 + closeout · 决定 round2 是否跑

## 不变量沿用

详 [`CLAUDE.md`](../../CLAUDE.md) · memory `feedback_codex_pen_windows_visual_check` 工具链 + 派单纪律

## 挂账留

- 14 验收点是「集中清算」式派单,可拆任意子集独立跑
- 若 Codex Pen 资源限制(分辨率 / GPU)→ 优先跑 P5+(本批新功能验证) + Ch4-6(narrative 类纯 UI 风险低)
- 派单完成后 closeout 沿 `codex_dispatch_*_closeout_*.md` 体例归档
