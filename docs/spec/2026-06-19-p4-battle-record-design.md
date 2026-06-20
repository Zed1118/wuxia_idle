# P4 战绩册 · 设计文档（design）

> 2026-06-19 brainstorm 拍板。P4「长期档案与探索联动」四本档案（藏经阁/兵器谱/战绩册/门派谱）
> 拆为四个独立子项依次做，**本 spec 只做第一本：战绩册**。其余三本各自走 spec→plan→实装。
> 上游：`docs/spec/playability_upgrade_master_spec_2026-06-09.md` §八「长期目标与收藏」；
> backlog `docs/spec/playability_phase2_backlog.md` §四 P4 + §五 #7（解锁时机，本 spec 给出战绩册这本的答案）。

## 1. 目标与边界

**一句话**：把已做完的战后高光（英雄镜头 / 珍稀掉落 / 首胜战报）永久收藏成一本「Boss 首胜纪念册」。

**范围**：一 Boss 一纪念，主线 **21** Boss（`data/stages.yaml` isBossStage=true）+ 爬塔 **6** Boss（`data/towers.yaml` bossKind，5/15/25 小 + 10/20/30 大）= **27 条封顶**。Boss-only，零膨胀（不收非 Boss 关，避 BattleReplayRecord 膨胀教训）。

**不做**（红线）：集齐不发任何奖励（§5.1 不做战令/任务/红点）；纯表现层不碰数值（§5.4）；离线挂机不产生纪念（§5.5）。

## 2. 数据模型

新建 Isar collection `BossMemory`（一档一 Boss 一条），saveVer `0.25.0 → 0.26.0`。

| 字段 | 类型 | 说明 | 可空 |
|---|---|---|---|
| `saveDataId` | int | 档位 | 否 |
| `bossKey` | String | 稳定键：主线=stageId / 爬塔=`tower_floor_<N>` | 否 |
| `source` | enum `BossMemorySource{mainline,tower}` | 分组维度（EnumL10n 显示名） | 否 |
| `groupIndex` | int | 分组排序序号：主线由 stageId 派生一个稳定 section 序（Ch1-6 在前，心魔/轻功/群战各成独立 section 排其后）/ 爬塔=层号 | 否 |
| `bossName` | String | 首胜时快照名（立绘渲染时从 def iconPath 取，不存路径） | 否 |
| `firstClearedAt` | DateTime? | 首胜时间（塔层回填无精确日期则空） | 是 |
| `isPreRecord` | bool | 回填骨架标记（true=本功能上线前击败，战绩不详） | 否 |
| `totalDamage` / `critCount` / `totalTicks` | int? | 首胜战绩（冻结，回填条目为空） | 是 |
| `topContributorName` | String? | 最高输出者名（英雄镜头同源） | 是 |
| `topContributorDamage` | int? | 最高输出者伤害 | 是 |
| `treasureName` | String? | 首胜珍稀掉落名（复用 `pickTreasureHighlight` 选出的 highlight；无珍稀掉落则空） | 是 |
| `treasureTier` | enum? `EquipmentTier` | 宝物阶（tier 色） | 是 |
| `rosterNames` | List<String> | 首胜出战阵容角色名 | 否（空列表） |
| `rosterPortraits` | List<String> | 阵容立绘路径（与 names 同序） | 否（空列表） |
| `defeatCount` | int | 击败次数（重打累加，不覆盖纪念，默认 1；回填骨架=1） | 否 |

denormalize 派生值（不存 seed+ops replay，守 BattleReplayRecord 删除教训：存统计/文本不存回放）。

## 3. 留档流程

新建 `BossMemoryService`（纯逻辑，可单测）。victory hook 末尾加一次后置调用，**不碰战斗结算/伤害公式**。

- **首胜**（`isBossStage && isFirstClear`）→ 建完整纪念。victory 时数据全已可得（见调研：stageId/层号、TopDamageContributor、BattleStatsSummary、DropResult、出战 activeCharacterIds 均在 `stage_entry_flow._applyVictoryResolution` / `tower_entry_flow._applyTowerVictoryResolution` 链路上）。
- **重打**（已有同 `bossKey` 纪念）→ 仅 `defeatCount++`，幂等，不覆盖首胜快照。
- **老档回填**（0.25→0.26 迁移，`_migrateSaveData` 内）→ 扫 `MainlineProgress.clearedStageIds`（过滤 isBossStage）+ 同序 `clearedAt` / `TowerProgress` 已过 Boss 层（≤ highestClearedFloor 的 5/10/15/20/25/30）→ 建 `isPreRecord=true` 骨架：Boss+日期（塔层无 per-floor 日期→ `firstClearedAt=null`），战绩字段全空，`defeatCount=1`。幂等（已存在同 bossKey 不重建）。

接线点（加法，不改既有行为）：
- `lib/features/mainline/presentation/stage_entry_flow.dart`（主线 victory）
- `lib/features/tower/presentation/tower_entry_flow.dart`（爬塔 victory）

## 4. 展示层

新 feature `lib/features/battle_record/`（domain / application / presentation 三层）。

- **`BattleRecordScreen`（战绩册主屏）**：分组列——主线按章（Ch1-6 + 心魔/轻功/群战）、爬塔按层。每 Boss 一卡：
  - 已击败 → 纪念缩略卡：Boss 立绘 + 名 + 首胜日期 + 「击败 N 次」。
  - 未击败 → 剩影占位：剪影 + 章节位 + 「未会之敌」（不剧透具体 Boss，不显总数）。
- **`BossMemoryDetailScreen`（单 Boss 纪念详情）**：立绘 + 首胜战报卡（总伤害/暴击/回合）+ 最高输出者（英雄）+ 掉落宝物 + 出战阵容 + 击败次数。`isPreRecord` 条目战绩区显「此役不详 · 记录之前」。
- **主菜单入口**：加「战绩册」按钮，谓词 = 存在 ≥1 条非占位纪念才显（首次击败任一 Boss 前隐藏，守 §5.7）。设计成以后能平滑挪进统一「档案阁」hub（不为未建的另三本提前造 hub）。
- **VISUAL_ROUTE**（目检）：`battle_record`（已击败+剩影混合态）+ `boss_memory_detail`（完整 vs pre-record 两态）。

## 5. 文案与配置（§5.6）

- UiStrings 新增：屏标题、「未会之敌」、「此役不详 · 记录之前」、「击败 N 次」、段标、详情各区标题。
- EnumL10n 新增：`BossMemorySource` 显示名（主线征程 / 爬塔问鼎 之类）。
- numbers.yaml：本功能无新数值（纯展示）；如需占位排版常量也优先复用现有 token，不新增数值。

## 6. 红线合规

| 红线 | 守法 |
|---|---|
| §5.1 反留存 | 集齐不发奖励，无每日/登录/战令/红点清单 |
| §5.4 数值 | 纯展示，0 伤害公式调用，0 新战斗数值 |
| §5.5 在线=离线 | 离线走 offline_recap 涓流不跑 Boss 战，天然不产生纪念（同英雄镜头边界） |
| §5.6 不硬编码 | 文案 UiStrings / 显示名 EnumL10n / 无散写中文 |
| §5.7 先感受 | 入口首胜后才现；剩影不剧透 |

## 7. 测试

- `BossMemoryService` 单测：首胜建完整 / 重打仅累加 defeatCount / 幂等 / 回填骨架（主线带日期 + 塔层无日期分支 + 已存在不重建）。
- 迁移测：0.25→0.26 从已通关进度回填，断言 isPreRecord + 战绩字段空。
- widget 测：主屏已击败+剩影两态 / 详情 pre-record vs 完整两态 / 主菜单入口门控谓词。
- 红线测：0 数值断言；离线路径不触发纪录。
- hook wiring 测：主线 + 塔 victory → 对应 bossKey 纪念落账。

## 8. 架构隔离

数据层（`BossMemory` + service 纯逻辑）/ 留档（victory hook 后置加法调用）/ 展示（独立 feature 只读 provider）三层边界清晰；service 不依赖 Flutter 可纯单测；屏不写库。

## 9. 后续（不在本 spec）

P4 另三本：藏经阁档案化 / 兵器谱 / 门派谱，各自独立 spec。战绩册主屏设计预留「以后挪进档案阁 hub」的可能，但 hub 本身待四本中第二本启动时再评估。
