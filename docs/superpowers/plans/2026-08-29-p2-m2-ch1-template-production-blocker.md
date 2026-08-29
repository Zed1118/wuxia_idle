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
