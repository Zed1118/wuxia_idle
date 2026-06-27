# 弟子加入战斗后移至终局解锁 · Design

> 日期：2026-06-27
> 阶段：1.0 长线打磨期
> 状态：用户已拍板方向（方案 A：纯配置后移 + 旧档祖年化）。本文只定设计与拆分边界，不实现代码。

## 1. 目标与动机

把大弟子（senior）/二弟子（junior）加入出战队伍的解锁时机，从现有的**中期**（Ch2 末 `stage_02_05` 收大弟子 / Ch3 末 `stage_03_05` 收二弟子）**后移到全主线通关后**（`stage_06_05` 通关时一并拜入）。

**动机（用户拍板）**：节奏——中期就给满 3 人把主线打得太轻松；拉长「祖师单人」期，把组队的爽感留到终局。整条主线变单人挑战是**有意为之**，不是要把主线调简单。

## 2. 现状（探查结论）

- 弟子已实装：通关 `stage_02_05`/`stage_03_05` 后经 `DiscipleJoinService.joinForClearedStage` 懒创建并 append 到 `SaveData.activeCharacterIds`（最多 3 人 3v3）。配置在 `data/numbers.yaml` `disciple_joins`（两条，各带 `narrative_id` 拜师剧情）。
- 飞升五条件（`ascension_models.dart` `canAscend`）：武圣 + 心魔07 + **`stage_06_05` 通关** + **有弟子** + 在阵。**飞升本就在全主线后**。
- 真传位 / 师承遗物 transfer（`ascend_service.dart performAscend`）依赖弟子存在（target 必须是现存弟子，否则 `StateError`）。
- Ch4-6 主线剧情**不涉及**玩家弟子（探查确认），后移不破叙事。

## 3. 设计（方案 A：纯配置后移）

### 3.1 改动核心
`data/numbers.yaml` `disciple_joins` 两条的 `stage_id`：`stage_02_05` / `stage_03_05` → 均改为 `stage_06_05`。`role`(senior/junior)、`master_slot_index`、`narrative_id` 不变。注释同步（删除「Ch2末/Ch3末/飞升前满队」旧口径，改「全主线通关后一并拜入」）。

### 3.2 一关触发两次拜入
改后 `stage_06_05` 命中**两条** `disciple_joins`。需让拜入服务与剧情 hook 遍历该关**所有**匹配条目（senior 先、junior 后），连续走两段拜师叙事 + 立绘，最后满队：
- `DiscipleJoinService.joinForClearedStage(stageId)`：从单条匹配改为遍历所有匹配条目，逐条懒创建。
- `disciple_join_hook`：从读单个 `narrative_id` 改为按匹配条目顺序依次弹 `NarrativeReaderScreen` + `DiscipleJoinOverlay`。
- 幂等不变：`triggeredDiscipleJoinStageIds`（关级防重）+「该 role 已存在则跳过」（角色级防重）双保险。

### 3.3 飞升 / 真传 / 师承遗物
**不改**。`stage_06_05` 胜利 → 拜入两弟子 → 同一时点 `mainline0605Cleared=true` 且弟子在场 → 飞升五条件可满足，弟子正好到位，无空列表 / `StateError`。时序天然吻合。

### 3.4 旧档祖年化（不写迁移 / 不抽走）
- 已触发 02_05/03_05 的存档：弟子已在 `activeCharacterIds`，06_05 触发被「role 已存在」guard 跳过，不重建、不重复剧情。
- 已通关 06_05 的老档：无影响。
- 未拜入的进行中档 / 新档：今后只在 `stage_06_05` 拜入。
- **不**从任何存档移除已有弟子（grandfather）。新规只影响今后没触发过的拜入。

### 3.5 叙事（可选微调）
拜师文案「往后这条江湖路，我陪你走」在终局后出现，语义指向飞升/爬塔/周目的「后续江湖」，可接受。如想更贴可微调一句，**非必须**，本次不强求。

## 4. 平衡（关键风险 · 独立验证项，不在本次静默调参）

整条主线变单人，Ch4-6 原可能按 3 人调过。**必须验证武圣单人能通 Ch4-6（尤其 `stage_06_05` Boss 52000 血）**：
- 用 `balance_simulator` 跑单人（正常 + 极值 build）× Ch4-6。
- 若不可通：把敌人/关卡调参作为**单独待用户拍板项**，不在本次实现里静默 buff 玩家或 nerf 敌人。
- 本 spec 范围 = 解锁时机后移；平衡校准是其下游、独立决策。

## 5. 测试

- `test/features/lineage/application/disciple_join_service_test.dart`：拜入时机断言 `stage_02_05`/`stage_03_05` → `stage_06_05`；新增「一关连续触发 senior+junior 两次拜入 → 满队」覆盖。
- `test/features/ascension/application/ascend_service_test.dart`：fixture 语义改为「弟子在 06_05 后才有」；补「06_05 前无弟子 → `canAscend=false` / 飞升屏显无弟子」用例。
- 旧档祖年化：补一条「已有 senior 的存档过 06_05 → 不重建、不重复剧情、junior 正常补入」覆盖。

## 6. 不做（YAGNI）

- 不做弟子分时段终局解锁（不在爬塔某层再拆一个）。
- 不改飞升/真传/师承遗物逻辑。
- 不在本 spec 内调主线数值平衡（见 §4，独立项）。
- 不动旧档（不写迁移、不抽走弟子）。

## 7. 影响文件清单

- `data/numbers.yaml`（`disciple_joins` 两条 stage_id + 注释）
- `lib/features/lineage/application/disciple_join_service.dart`（遍历多匹配条目）
- `lib/features/lineage/presentation/disciple_join_hook.dart`（顺序弹多段拜师）
- 上述 3 个测试文件
- 验证：`flutter analyze` 0 issue + 全量 `flutter test`（含弟子/飞升族）
