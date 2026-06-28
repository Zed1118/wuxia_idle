# 战前情报弹窗 opt-in 重做 设计

**日期**：2026-06-28
**分支**：worktree-stage-intel-optin
**类型**：表现层重做（无 schema / saveVer / numbers.yaml）

## 背景

睡觉模式 Codex 批的第 11 项「战前情报」(`30c5fd54 Add stage prebattle intel dialog`，集成分支 `codex/nightly-2026-06-28-integration` 保留) 暂缓未合入 main，原因有二：

1. **挂在 `onTap`**：每点关卡必弹一个含「敌阵/整备/风险/可能收获」四 section 的全屏框，确认「开战」才进战斗 → 违「即拖即放立即出手」爽感主旋律（memory `feedback_wuxia_combat_satisfaction_principle`）。
2. **四重冗余**：四个 section 里有三个与当前 `stage_list_screen.dart` 行内已展示项重复。

本次把它重做成 opt-in 纯查看入口并去冗余后合入。

## 现状（main `0e610bc0`）

`stage_list_screen.dart` 的 `_StageRow` 行内已展示：

- 关卡名 + `首领` tag
- `InlineLootSummaryLine`（爆率行内·睡觉模式 01）— 推荐境界 + 掉落摘要
- subtitle「敌人数 N」
- `_StagePreparationBar`（整备条·睡觉模式 14）— 整备图标 + 推荐境界 + 难度判语 + 行动建议
- `WeaknessHintLine`（通关后 Boss 弱点/抗性）
- 右侧 `info_outline` 图标（`stage_list_screen.dart:499`）→ `showLootRumorDialog`（掉落传闻弹窗）

即「opt-in 信息入口」机制（行尾 info 图标 + 行 onTap 直接进战斗）**已存在**。

### 原 11 四 section 的冗余对照

| 原弹窗 section | 行内是否已有 | 处置 |
|---|---|---|
| 敌阵（每敌 名·境界·门派·首领/蓄力 tag） | 仅 subtitle「敌人数」+ 通关后 WeaknessHint | **保留**（行内独有价值） |
| 整备（推荐境界 + 难度判语 + 境界达标建议） | `_StagePreparationBar` 已全有 | **删除** |
| 风险 | 整备条 actionText 部分覆盖（境界低） | **部分保留**（删境界低一行） |
| 可能收获（`LootRumorContent`） | 现有 info 图标已弹同一个 | **保留**（图标原职责，合并进新弹窗） |

## 方案（已与用户确认 = 方案 A）

把现有 info 图标从「掉落传闻」**升级为「战前情报」综合弹窗**，只补行内没有的「敌阵 + 应对」，并入已有掉落，删掉与整备条冗余的整备/难度。`onTap` 关卡行直接进战斗，不变。零新增行内元素（守睡觉模式 14 信息密度警告）。

### 隔离边界

- `loot_rumor_dialog.dart`（`showLootRumorDialog` / `LootRumorContent`）**完全不动**：另有 `tower_floor_card.dart:318`（爬塔）+ `stage_preview_card.dart` 在用。
- 新弹窗内部仍 `import` 并复用 `LootRumorContent` 渲染「可能收获」。
- 仅 `stage_list_screen.dart` 那一个 info 图标 onPressed 改指向 `showStageIntelDialog`。

## 弹窗设计

**入口**：`_StageRow` 右侧 `info_outline` 图标，`onPressed: () => showStageIntelDialog(...)`，tooltip 改 `UiStrings.prebattleIntelTitle`（「战前情报」）。

**签名**：纯查看 opt-in，不返回战斗决定 → `Future<void> showStageIntelDialog(context, {required StageDef stage, required DropRumorTable rumorTable, RealmTier? currentRealm})`。单个「关闭」按钮（删原版「稍候/开战」双 action）。

**四段内容**：

1. **敌阵** — `stage.enemyTeam` 每敌一行：`名 · 境界 · 门派 [· 首领/蓄力 tag]`。空队列显「未见敌踪」。
2. **应对** — 由 `stage.enemyTeam` + `isBossStage` 派生（原 `_teamPreparationLines`，**剔除**推荐境界/难度判语/境界达标三行）：
   - 首领关 → 留足内力，先随从后攻坚
   - 敌 ≥3 → 备一门群体招先清场
   - 有蓄力招 → 保留破招/爆发内力
   - 全队同门派 → 提示克制路数（`_counterSchoolFor`）
   - 以上皆无 → 该段不显（不强行兜底废话）
3. **风险** — （原 `_RiskIntel`，**剔除**「境界低于推荐」一行 → 整备条已有）：
   - 首领关 → 战败额外折损，勿空内力硬拼
   - 有蓄力招 → 未打断可瞬间扭转
   - 敌 ≥3 → 拖久易被围攻
   - 以上皆无 → 「未见明显险兆」兜底（保留，给玩家一个安心确认）
4. **可能收获** — `LootRumorContent(table: rumorTable, currentRealm: currentRealm)`，复用。

`currentRealm == null` 时：敌阵/应对/风险/掉落均宽容（应对与风险本就不依赖玩家境界，掉落沿用 LootRumorContent 的 null 宽容）。

## 文案（`strings.dart`）

复用原 11 已写的 `prebattle*` 常量，做增删：

**删除 6 条**（冗余整备/难度）：
- `prebattleRecommendedRealm`
- `prebattleDifficulty`
- `prebattlePrepRealmReady`
- `prebattlePrepRealmLow`
- `prebattlePrepRealmUnknown`
- `prebattleRiskRealmLow`

（其中 `prebattleDifficulty` 依赖 `difficultyLabelColor`，删后 `stage_intel_dialog` 不再 import `stage_preview_card`/`stage_difficulty` 的难度评估。）

**改 1 条语义**：`prebattleIntelPreparationSection`「整备」→ 新增/改为「应对」（避免与行内整备条重名混淆）。

**「开战」按钮**：`prebattleIntelStart` 不再用于战斗确认；改用通用关闭文案（复用既有「关闭」类 string，若无则新增 `prebattleIntelClose`）。`prebattleIntelCancel`「稍候」删除。

保留：`prebattleIntelTitle` / `prebattleIntelDialogTitle` / 各 section 标题（敌阵/风险/可能收获）/ `prebattleIntelNoEnemy` / `prebattleIntelBossTag` / `prebattleIntelChargeTag` / `prebattleEnemyLine` / `prebattlePrepBoss/Group/Charge/CounterSchool` / `prebattleRiskBoss/Charge/Outnumbered/None`。

## 改动文件清单

| 文件 | 改动 |
|---|---|
| `lib/features/loot_preview/presentation/stage_intel_dialog.dart` | **新建**（精简自原 11：删整备 section / 改 `Future<void>` + 单关闭按钮 / 删难度依赖） |
| `lib/features/mainline/presentation/stage_list_screen.dart` | info 图标 `onPressed` 改 `showStageIntelDialog`、tooltip 改、加 import |
| `lib/shared/strings.dart` | 增删上述 `prebattle*` 文案 |
| `test/features/loot_preview/stage_intel_dialog_test.dart` | **新建**（复用原 11 fixture：断言敌阵/应对/风险/收获在、整备/难度行不在、单关闭按钮） |
| `test/features/mainline/presentation/stage_list_screen_test.dart` | 断言行尾图标弹「战前情报」（含敌阵）而非纯掉落 |

**无** schema / saveVer / numbers.yaml / data 改动。

## 验收标准

1. `flutter analyze` 0 issue。
2. 全量 `flutter test --no-pub -j1` 全绿（基线 3280 passed/1 skip，净增 dialog 测）。
3. 点关卡行 → 直接进战斗（无强制弹窗，`onTap` 行为不变）。
4. 点行尾 info 图标 → 弹「战前情报 · 关卡名」含敌阵/应对/风险/可能收获四段，无「整备/推荐境界/难度判语」冗余行，单「关闭」按钮。
5. 爬塔屏 `tower_floor_card` 的掉落图标行为不受影响（`loot_rumor_dialog` 未动）。
6. 真机 `flutter run -d macos` 目检弹窗排版与信息密度（spec 外，实装后跑）。

## 挂账 / 范围外

- 真机手感目检（关卡列表信息密度、弹窗排版）留实装后 `flutter run -d macos`。
- 集成分支 `codex/nightly-2026-06-28-integration` 重做完成后可退役（与遗留 worktree 清理一并处置，非本切片）。
