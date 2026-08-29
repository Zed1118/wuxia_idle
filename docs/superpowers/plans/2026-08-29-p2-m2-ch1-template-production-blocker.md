# M2 第一章五关四模板生产化阻塞（2026-08-29）

## 结论

本单在实装前触发交接宪法 §10，必须停下请用户冻结产品数值，不得由执行端直接把 candidate 配置提升为生产值。

- 基线：`45829dddad9c4b264d30e9701a8aaec993522222`
- 分支：`codex/p2-m2-ch1-templates-20260829`
- 预热：已按 §7 完成 `libisar.dylib` 复制、`flutter pub get`、`build_runner`
- 生产现状：`data/combat/manifest/stage_assignments.yaml:1-14` 仅 `stage_01_03` 为 migrated，其余四关仍为 legacy
- 架构结论：现有 typed encounter schema、loader 与生产 runtime 路径可承载四模板，未发现必须新增 save/schema 字段的不可调和冲突

## 触发证据

1. `test/fixtures/phase2/combat/ch1_candidate/manifest/stage_assignments.yaml:1-2` 明确声明该目录仅为非生产 candidate，且每个数值都是未冻结的评审候选。
2. `docs/dispatch/phase0a_overhaul/task_registry.yaml:1450-1475` 将该包登记为 `P2-M2-D01-CH1-CANDIDATE-CATALOG`，并明确规定关卡编排与数值只能作为 candidate evidence，不能证明 production tuning。
3. `docs/dispatch/phase0a_overhaul/decision_registry.yaml:414-442` 将 `activeLimit`、补兵阈值、攻击令牌与各关精确总数列为 tuning；其中关卡数量和补兵编排尚无生产冻结。
4. 交接宪法 §10 要求“数值与成长规则、schema 与迁移”一律停下问用户；本单无权以“按推荐推进”代替对具体生产数值的冻结。

## 待拍板的推荐方案

推荐将已有 candidate 的四关编排整体冻结并原样生产化，`stage_01_03` 继续使用已上线的 `40 / 12 / 4` 伏击配置：

| 关卡 / 模板 | 总敌人 | 活跃上限 | 补兵阈值 | 预警 / 保护 tick | 令牌 `melee/ranged/charge/support` |
|---|---:|---:|---:|---:|---:|
| `stage_01_01` / 破路 | 25 | 10 | 2 | 20 / 10 | 2 / 1 / 1 / 0 |
| `stage_01_02` / 据点 | 25 | 10 | 2 | 24 / 12 | 1 / 1 / 1 / 1 |
| `stage_01_03` / 伏击 | 40 | 12 | 3 | 30 / 15 | 1 / 1 / 1 / 1 |
| `stage_01_04` / 斩将 | 3 | 3 | 0 | 20 / 10 | 1 / 0 / 1 / 1 |
| `stage_01_05` / 斩将 | 2 | 2 | 0 | 30 / 15 | 1 / 0 / 0 / 1 |

拍板范围还包括 candidate 中已有的 spawn entry 顺序、四类山匪构成、入场点/站位/行为 ID 与 objective 组合；不新造玩家可见文案，不改 `numbers.yaml`，不改 saveVersion。

## 解锁后的执行边界

用户明确批准上述冻结后，本分支才可继续：将四关提升到生产 catalog/manifest，保持现有 typed schema，补生产路径与五关顺序测试，再依宪法完成 commit 后双向破坏证红、全量、receipt、gate、合并、push 与 CI 核验。

## 首次批准后发现的 runtime 坐标缺口

用户已于 2026-08-29 批准上述 candidate 数值与编排，但生产消费链复核发现 candidate 不含 runtime binding 坐标，因此仍不能实装：

1. candidate 目录只有 archetype、encounter 和 stage assignment 三个 YAML，没有 `runtime_bindings.yaml`。
2. `lib/data/combat_runtime_binding_loader.dart:212-227,257-263` 强制每个 migrated stage 都必须提供入场点 `spawn_position` 和站位 `world_position`，缺失 binding 直接 fail closed。
3. `test/data/phase2/ch1_candidate_runtime_construction_matrix_test.dart:269-280` 没有走生产 binding，而是把所有敌人手设为 `x: 1`；它不能证明四关生产位置可用。

推荐不新造一套场地数值，只从已生产的 `stage_01_03` 坐标调色板中复用以下点位：

| runtime ID | 推荐坐标 `(x, y)` |
|---|---:|
| `ch1_entrance_s01_road_west` | `(-520, 80)` |
| `ch1_entrance_s01_road_ridge` | `(0, -120)` |
| `ch1_entrance_s01_road_exit` | `(520, 80)` |
| `ch1_position_s01_near` | `(-240, 140)` |
| `ch1_position_s01_middle` | `(0, 140)` |
| `ch1_position_s01_far` | `(240, 140)` |
| `ch1_entrance_s02_gate` | `(-520, 80)` |
| `ch1_entrance_s02_roof` | `(0, -120)` |
| `ch1_entrance_s02_yard` | `(520, 80)` |
| `ch1_position_s02_gate` | `(-240, 140)` |
| `ch1_position_s02_roof` | `(0, -40)` |
| `ch1_position_s02_yard` | `(240, 140)` |
| `ch1_entrance_s04_duel_court` | `(520, 80)` |
| `ch1_position_s04_guard_arc` | `(-120, 120)` |
| `ch1_position_s04_commander_center` | `(0, -40)` |
| `ch1_entrance_s05_peak_ring` | `(0, -120)` |
| `ch1_position_s05_guard_arc` | `(-120, 120)` |
| `ch1_position_s05_commander_center` | `(0, -40)` |

四关 `base_enemy_id` 不需要新拍板，分别强绑现有 `StageDef.enemyTeam.single`：`enemy_xueTu_thug_a`、`enemy_xueTu_rufflian_a`、`enemy_xueTu_qingshan`、`enemy_xueTu_umbrella`。行为、AI、攻击集和视觉 variant 全部复用已生产的山匪四角色 binding，不引入新值。

## 全生产链复核发现的模板语义冲突

第二次坐标批准后，继续沿真实 factory 与 objective source 向下复核，发现 candidate 仍不能直接生产化：

1. `phase0a_mainline_production_encounter_factory.dart:107-130` 强制任意 `activeLimit` 滑窗内坐标全唯一。candidate 破路/据点各只有 3 个 position ID 却允许 10 个活跃，第四关两名护卫共用一点，生产 factory 会直接抛错。
2. 同文件 `:190-198` 对所有敌人只发 `TargetDefeated`，不发 `CommanderDefeated`，也没有 checkpoint/anchor projector。因此破路的“清敌 + 到达出口”、据点的“毁锚点或斩首”以及两关斩将都无法完成。
3. `phase0a_mainline_repository_runtime_binding_adapter.dart:76-82,117-168,240-269` 以单个 legacy `StageDef.enemyTeam` 为整关数值模板，再用山匪 role 覆盖技能/视觉。在 `stage_01_04/05` 中，这会使护卫继承 Boss 标记，并使「青衫汉子/撑伞高人」的旧 Boss 技能和视觉被锣首领 role 覆盖；这是玩家可见语义变更，不能默认。

### 一次性推荐冻结包

为了不改 save/schema、不新增文案/美术，推荐冻结下列生产语义：

- **唯一站位**：破路与据点分别改用 `ch1_position_s01_slot_01..10` / `ch1_position_s02_slot_01..10`，按 spawn entry 顺序循环分配；坐标原样复用黑风岭 slot 01..10。第四关改为护卫左 `(-120,120)`、护卫右 `(120,120)`、主将中 `(0,-40)`；第五关保持护卫 `(-120,120)` + 主将 `(0,-40)`。前一次批准的三点 position 映射被本条取代，entrance 坐标不变。
- **破路出口**：玩家中心跨过已批准的道路出口 `x >= 520` 时发一次 `CheckpointReached(ch1_s01_checkpoint_exit)`；平面 `all` 语义允许先到出口再清敌，不新造判定半径。
- **据点锚点**：在 `stage_01_02` 中，第一个从 `ch1_entrance_s02_gate` 来的敌人被击败时发 `AnchorDestroyed(ch1_s02_anchor_gate)`；第一个从 `ch1_entrance_s02_roof` 来的敌人被击败时发 `AnchorDestroyed(ch1_s02_anchor_gong_rack)`。不加新物件美术和 UI 文案，以据点守军作为已有锚点的真实战斗触发器。
- **斩将投影**：严格从 typed `defeat_commander` 引用构造 `CommanderDefeated`，从 `defeat_targets` 构造 `TargetDefeated`；不按 actor ID 文字或 role 猜测。
- **Boss 身份**：第四/五关只有 typed commander 引用指向的 entry 保留 legacy StageDef 的 Boss 姓名、图标、技能、蓄力与 phase；其余护卫使用山匪 role 技能/视觉并显式清除 Boss-only 状态。commander 仍使用锣首领的令牌种类、AI 行为和已批准倍率，因此四 role 与旧 Boss 可学攻击同时保留。

实装时只扩展现有 production mapper/adapter 的显式投影与快照组装，不改 `StageDef`、不改 saveVersion、不加 YAML schema 字段，不改禁区文件。
