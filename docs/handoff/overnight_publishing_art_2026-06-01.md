# 挂机 closeout · 出版美术 Phase A 章节页 + 神物边框（2026-06-01）

> autonomous 整夜挂机 · 用户睡眠 · 全程 TDD + 每切片 commit · 待用户晨起验收
> spec：`docs/superpowers/specs/2026-06-01-overnight-publishing-art-design.md`

## 完成（3 切片，全 merge）

| 切片 | commit | 内容 |
|---|---|---|
| 1 章节页封面接线 | `7a8dd9f` | `chapterCoverPath(int)` helper + `_ChapterCard` 顶部封面条(96h BoxFit.cover·锁章调暗) + `ChapterTransitionScreen` 章首全宽插图(160h) + `chapter_list` VISUAL_ROUTE |
| 2 神物/宝物差异化 | `0c62dbf` | `isHighTreasureTier()` + 详情大图高阶全周粗边框(width3·§5.4「更强边框」) + 题字加大(fontSize22+letterSpacing) |
| 3 关卡列表封面头 | `403fb36` | StageListScreen 顶部章节封面头(复用 chapterCoverPath·§5.3「关卡场景感」) |

均 art-decoupled：图未到位走 errorBuilder 兜底不破布局，**MJ Ch1-6 封面落位即显于 3 处**（章节卡 + 章首过场 + 关卡列表头）。

## 自主决策（记录）

- **Phase C 抽 Wuxia* 组件 → 否决**：grep 审 `Border.all(color:)` 30 文件/51 处但高度异构（panel/badge/card/slot 各异），无真 DRY 重复。强抽违 memory `feedback_avoid_over_engineer_abstraction`。不为凑组件硬抽。
- **战斗屏轻改 → 不做（unattended 风险）**：触 battle 回放架构（最严守子系统），无人值守不碰。留有人值守会话。
- 章节封面**不引 yaml/loader**：沿既有 index/enum-keyed inline asset 体例（`technique_panel:152`），单一真相源 helper，§5.6 grey-area 已消解。

## 验证

- `flutter analyze`：0 issues（全量）
- `flutter test`：**1632 测 / 1 skip 全绿**（baseline 1628 + 新 4：chapterCoverPath 2 + isHighTreasureTier 2）。首跑 42 fail 系 worktree libisar.dylib 截断(环境)，拷主仓 dylib 后全绿。
- 新增/调整测试：chapter_assets_test / tier_colors_test(+isHighTreasure 2) / chapter_list_screen_test(扩 viewport 2000 适配封面条) / visual_route_test(+chapter_list)

## 待用户晨起

1. **MJ 章节封面归位**：**Ch1-4 已归位 + pngquant/oxipng 压缩**（8.1M→1.7M · chapter_01-04_cover.png · 我多模态亲验 ch1 无 banding）。**Ch5 原出竖图(--ar 没生效)废 + Ch6 失败缺失 → 已重给 2 prompt**(强化 16:9 + no-people + Ch6 moderator-safe 改写)，图回来归位 chapter_05/06_cover.png。
2. **Codex 视觉验收**：`chapter_list` VISUAL_ROUTE 已就位 + 神物边框走装备详情。app 待 build（晨起我备派单，或图归位后一起验更直观）。
3. Phase A 出版美术 5 屏（主菜单/心法/角色/章节/装备）此后基本齐；下一波候选：战斗屏轻改（有人值守）/ 战斗场景 MJ 批 + 接线。

## 踩坑

- 章节卡加 96px 封面条 → 默认 viewport 装不下 6 卡，扩 `setSurfaceSize(1024,2000)`（memory `feedback_listview_widget_test_viewport`）。
- `Border` 无 `copyWith`，高阶/普通边框分支用 `Border.all` / `Border(bottom:)` 直接形式。
- **fresh worktree libisar.dylib 截断**（memory `feedback_fresh_worktree_libisar_dylib` 复现）：worktree 自带 dylib 664KB 截断（`x86_64 slice extends beyond end of file`），全量首跑 42 Isar 测 dlopen 失败（非代码 bug）。从主仓 `cp libisar.dylib`（2187KB）修复 → 全绿。下次 fresh worktree 跑 Isar 测前先拷 dylib。
