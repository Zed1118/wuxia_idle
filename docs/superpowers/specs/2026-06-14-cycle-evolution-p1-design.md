# P1 周目进化(江湖记招 / 问鼎轮回)· 实装设计

> 来源:用户 2026-06-14 拍板。承接 master spec `2026-06-13-semi-manual-battle-seed-replay-cycle-design.md` 的 **P1**(P0 单关闭环已实装并合 main)。
> 拍板:范围=主线+爬塔一起(战败诊断帖单独后续);反制词条=结构化词条池复用现机制(5 个);深度=主线 3 周目/爬塔 2 周目(架构预留 5),scale +6%/周目;周目选择 UI=选关屏 tile 内联;GDD §5.5 已覆盖周目(P0 加注),不再改。

## 一 · 目标与范围

让已通关关卡/全塔可挑战「下一周目」:敌人进化(数值 scale +6%/周目 + 反制词条「江湖记招」),新周目=新战斗→原 seed 失效→重新手动单步通关→再解锁该周目自动刷。

**做**:cycleIndex 入进度模型 + cycle-aware battleKey/自动判定 + 敌人 cycle scale + 5 反制词条池 + 周目选择 UI + 江湖记招叙事 hook(generic 一版)。
**不做(后续独立波)**:战败诊断帖、per-stage 宿敌定制叙事、文档2 其余创新点。

## 二 · 周目语义(不改解锁链)

- 关卡**解锁链仍按 cycle-1 通关推进**(打过上一关 cycle1→解锁下一关)。周目 2/3 是**已解锁关卡的可选高难重打**,不 gate 进度。
- 主线每关可推进到 cycle 3;爬塔全塔到 cycle 2(`cycle_evolution.max_cycle` 配置,预留 5)。
- 新周目敌人进化 = 新战斗 → `resolveAutoPlayMode` 对该 (关,周目) 无 record → `manualFirstClear` 强制手动;手动通关后录该周目 record → 解锁该周目自动。

## 三 · Schema(saveVersion 0.20.0 → 0.21.0)

- **MainlineProgress**(`mainline_progress.dart`):**保留** `clearedStageIds`/`clearedAt`(cycle1 解锁链不动)+ 新增 `clearedStageCycleKeys: List<String>`(每条 `"stageId#cycle"` = 该关该周目已手动通关)。
  - 派生:`highestClearedCycle(stageId)` = max cycle where key present(无则 0);`currentChallengeCycle(stageId)` = highestClearedCycle+1(clamp ≤ max_cycle)。
  - 迁移:旧 `clearedStageIds` 每项补 `"<id>#1"` 入 `clearedStageCycleKeys`。
- **TowerProgress**(`tower_progress.dart`):新增 `currentCycleIndex: int`(在爬的周目,default 1)+ `maxClearedCycle: int`(已 30 层通关到的最高周目,default 0);`highestClearedFloor` 语义改为「当前周目内最高层」。
  - 迁移:`currentCycleIndex=1`;`maxClearedCycle = (highestClearedFloor>=30 ? 1 : 0)`。
- 迁移单段加进 `isar_setup.dart` `_migrateSaveData`(沿现有 0.20 段体例);旧档天然兼容。
- service:`MainlineProgressService.recordVictory` 加可选 `cycle`(default 1)写 cycleKey;`TowerProgressService.recordClear` 接 cycle + 30 层满推进 maxClearedCycle;均加 query helper。

## 四 · battleKey / 自动判定接周目

- `stage_entry_flow` / `tower_entry_flow`:battleKey 传当前挑战 cycle(`stageBattleKey(id, cycle:)` / `towerBattleKey(floor, cycle:)` 已预留参数)。
- `resolveAutoPlayMode` 的 `isCleared` 改查「该关**该周目**是否手动通关」(`clearedStageCycleKeys` 含 `"id#cycle"`)。其余 4 态真相表不变。
- onVictory 录 record 用带 cycle 的 battleKey;recordVictory/recordClear 传 cycle。

## 五 · 敌人 cycle scale(numbers.yaml 新增 `cycle_evolution` 段)

- `_enemyToBattle()`(`stage_battle_setup.dart`)加 `cycleIndex` 参数:`hp/attack × (1 + scale_per_cycle×(cycle-1))`,`scale_per_cycle=0.06`。内力按同系数(放招预算)。buildEnemyTeam/buildTeams 链路透传 cycleIndex。
- 红线:cycle 3 主线 + 神物关 boss 实测 ≤ 50000 血 / 普伤 ≤8000(压测守);难度主靠词条非堆数值。

## 六 · 反制词条池(5 个 · 结构化 · 复用现机制)

配置驱动(numbers.yaml `cycle_evolution.traits`),`_enemyToBattle()` 按 (cycleIndex, isBoss) 给敌方 BattleCharacter 注入 `cycleTraits: Set<String>`;damage_calculator/strategy 消费。**纯复用现有战斗 hook,无新战斗子系统**。

| 词条 | 机制 | 复用 |
|---|---|---|
| 御体 yuTi | 该敌防御率 +pct(c2 +0.08 / c3 +0.12) | defense_rate |
| 反震 fanZhen | 玩家命中该敌→反弹固定内伤到攻击者(穿透防御) | InternalInjurySlot/震伤固定值 |
| 识破 shiPo | 该敌获蓄力破招技(多一记杀招) | chargeSkillId + 蓄力机制 |
| 凝甲 ningJia | 玩家对该敌暴击伤害 ×0.5 | 暴击系数路径 |
| 真气 zhenQi | 该敌内力上限 +pct → 多放一次大招 | 内力放招次数离散杠杆 |

**分配**(`cycle_evolution.trait_assignment`):主线 c2={御体} / c3={御体,反震,识破};爬塔 c2 普通层={御体,真气} / Boss 层={御体,反震,识破,凝甲}。

## 七 · 周目选择 UI(选关屏 tile 内联)

- 已通关关卡(主线 tile / 爬塔通关后)显示当前可挑战周目 + 「继续刷 cycle N(自动)」vs「挑战 cycle N+1(手动)」切换。复用 G3 选关屏 tile 体例(AutoPlayToggle 同区)。
- 选 cycle N+1 → 进战斗用该 cycle(manualFirstClear);cycle ≤ 已通关周目 → 沿 G3 自动/手动开关。
- 爬塔 currentCycleIndex 切换在 tower 屏顶部(全塔规则)。

## 八 · 江湖记招叙事 hook

- cycle ≥ 2 进战斗前一句提示(UiStrings,generic):「此敌已识得你的路数,见招拆招。」按挂载词条可附一句(如反震→「你的招式恐被借力反震」)。
- per-stage 宿敌定制叙事留后续。

## 九 · 硬约束 / TDD

- §5.4 数值红线不破;cycle scale + 词条参数全走 numbers.yaml(不硬编码);文案走 UiStrings。
- 确定性重放地基不动:新周目=新 seed 重新手动;cycleTraits 注入不引入无种子随机。
- TDD:① schema 迁移测(0.20→0.21,旧 clearedStageIds→cycleKey / tower cycle 迁移)② cycle scale 公式测 ③ 5 词条各机制测(御体减伤/反震内伤/识破蓄力/凝甲暴击减半/真气放招次数)④ resolveAutoPlayMode per-cycle isCleared 测 ⑤ 跨阶+周目压测守红线。每步 analyze 0 + 全量测不退。
- schema 改:升 saveVersion + `git grep "'0.20.0'" test/` 全仓改断言;worktree merge 回主前 `dart run build_runner build`。

## 十 · 实施顺序(依赖链)

1. **Schema + 迁移**(🔴 0.21.0,单点收口):MainlineProgress/TowerProgress 加字段 + service + 迁移 + 0.20.0 断言全仓改。
2. **cycle scale**(numbers.yaml `cycle_evolution` + `_enemyToBattle` cycleIndex 透传)。
3. **反制词条池**(cycleTraits 注入 + 5 机制消费,复用现 hook)。
4. **battleKey/resolveAutoPlayMode 接周目**(入口流传 cycle)。
5. **周目选择 UI**(选关屏 tile + 叙事 hook,Codex 视觉验收)。
6. 压测守红线 + 全量回归。
