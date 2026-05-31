# 挂机批 · 出版美术 Phase A/C 续 设计（autonomous）

> 2026-06-01 整夜挂机 · 用户授权自主拍板 + 全程 TDD + 每切片 merge · 用户睡眠 ~7-8h
> 主线（用户 AskUserQuestion 已定）：章节页封面接线（配 MJ Ch1-6 封面批）+ Phase C 抽 Wuxia* 组件
> 上游：`docs/PUBLISHING_ART_PASS_1_0.md` §5.3 章节页 / §7.2-7.3 组件

## 切片 1：章节页封面接线（art-decoupled，配 MJ 批）

**目标**：章节列表卡 + 章首过场加水墨封面图槽，图未到位时 errorBuilder 兜底不破布局；MJ Ch1-6 封面回来即落位。

**关键决策（autonomous）**：
- **不引 yaml/loader/provider**。章节是静态 `[1..6]`、screen 同步、标题已走 `UiStrings.chapterTitle(index)` 硬编码（非 data-driven）。封面按 index inline 取，**沿项目既有体例** `technique_panel_screen.dart:152` `'assets/techniques/tier_${tier.name}.png'` + errorBuilder shrink（§5.6 grey-area 已被既有 enum/index-keyed inline asset 体例消解；§17.1「单例常量可保留」）。
- **单一真相源 helper**：新 `lib/features/mainline/domain/chapter_assets.dart` → `chapterCoverPath(int)` = `'assets/scenes/chapter_${index.toString().padLeft(2,'0')}_cover.png'`（card + 过场屏共用，DRY，不在两处写裸路径）。
- `assets/scenes/` 已在 pubspec 注册（行 68），图落位即显。

**IN**：
- `chapter_assets.dart`：`chapterCoverPath(int)`（guard 1..6 外仍返回路径，errorBuilder 兜底；不抛）
- `_ChapterCard`：顶部加封面 banner（16:9，`Image.asset(chapterCoverPath)` + errorBuilder → 弱占位不破布局；locked 章 Opacity 调暗）。原 Row（标题/提示/卷轴 icon/StatusChip）保留在 banner 下。
- `ChapterTransitionScreen`：卷首顶部加全宽封面插图（同 helper + errorBuilder shrink）
- VISUAL_ROUTE `chapter_list`（seedMasterDisciple + land `ChapterListScreen`）供 Codex 验收
- 测试：`chapterCoverPath` 纯单测（路径格式 + padLeft）+ card/transition widget 测不 crash（errorBuilder 兜底）

**OUT**：章节 yaml 改 schema / 关卡内场景背景（stage sceneBackgroundPath 已另接）/ 章节卡完整重设计

## 切片 2+：Phase C 抽 Wuxia* 组件（先审重复再抽，避免 over-engineer）

**纪律**（memory `feedback_avoid_over_engineer_abstraction`）：先 grep 审 inline 重复，**有真重复才抽**，不为凑组件硬抽。
- 候选 `WuxiaTierFrame`：阶位色边框盒子在 character_panel `_SlotShell` + inventory `_Row` icon 框 + equipment_detail 大图框 多处 inline → 若 ≥3 处同构则抽。
- 候选 `WuxiaSealBadge`/`WuxiaRewardDialog`：审 inline 用法后定。
- 抽则：行为/颜色/降级语义不变 + widget 测锚 + 收敛 callsite。复用现有 `WuxiaColors`/`tier_colors`，严禁新色板（§17.3）。

## 切片 3（时间够）：装备页神物差异化边框（§5.4 边际项）

神物/宝物详情大图加铜金（`resultHighlight`）更强边框，区别寻常货 tier 色。小切片，按时间裁。

## 测试纪律（守 baseline 1628 测 / 0 analyze）

每切片 TDD red→green + 全量 analyze 0 + 相关测试文件全绿；末尾全量 `flutter test` 后一次 merge。
遵 memory：`feedback_isar_widget_test_deadlock`（纯渲染测不进 writeTxn）/ `feedback_listview_widget_test_viewport`（ListView 测扩 viewport）/ `feedback_image_asset_error_builder`（Image.asset 必带 errorBuilder）。

## 验收

CLI：analyze 0 + 全量绿。视觉：Codex 验章节页封面（图落位后）+ 组件统一后各屏不破。晨起 handoff 出 Codex 派单。
