# M2 第一章五关四模板决策与生产化记录（2026-08-29）

## 当前结论

本单先后触发的数值、坐标与模板语义决策已由用户在 2026-08-29 逐项批准。实装已完成，当前状态是“待宪法收工流程与 gate 判决”，不再是产品阻塞。下文保留最初阻塞及三次批准的完整证据链。

- 基线：`45829dddad9c4b264d30e9701a8aaec993522222`
- 分支：`codex/p2-m2-ch1-templates-20260829`
- 预热：已按 §7 完成 `libisar.dylib` 复制、`flutter pub get`、`build_runner`
- 初始生产现状：基线上仅 `stage_01_03` 为 migrated，其余四关为 legacy
- 当前分支实况：`data/combat/manifest/stage_assignments.yaml` 已将五关全部标记 migrated，并由 production encounter/runtime binding 闭合
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

## 批准后实装结果

- `data/combat/encounters/chapter_01_templates.yaml`、`data/combat/manifest.yaml`、`data/combat/runtime_bindings.yaml` 已闭合五关四模板与冻结 tuning/坐标。
- `phase0a_mainline_production_encounter_factory.dart` 从 typed objective 构造 target/commander/anchor/checkpoint 投影；stage01 仍严格只在玩家中心跨过 `x=520` 时发 checkpoint。
- `phase0a_mainline_repository_runtime_binding_adapter.dart` 为每个 entry 分配唯一负 `characterId`；仅 typed commander 保留旧 Boss 身份/技能/蓄力/phase，护卫明确去除 Boss-only 状态。
- headless/前台 bot 在清场后消费同一 typed checkpoint 导航命令，真人路径仍必须经键盘移动真实跨过出口，没有自动伪造目标完成。
- 相关 targeted 组已覆盖五关数量/活跃窗/坐标/唯一参与者 ID、精确 objective 投影、真实 migrated 四模式同核与键盘输入链；最终结论仍以 receipt 与 gate 为准。

## 首次 gate 判决与当前阻塞

READY tip `cf68918b72352d27f290f193de9ec1d8034e5fcb` 的第一次正式 gate 已于 2026-08-29 运行完整，结果为 `FAIL: test_deletions,receipt_crosscheck`。其余客观门均过：全量 `+5685: All tests passed!`、`error_block_count=0`、analyze `No issues found!`、format `1636 files (0 changed)`。receipt mismatch 只是将失败轮次计数推算为 `+5682`，下次可直接改为 gate 实测的 `+5685`。

无法在现行判据下自主修复的是 `test_deletions=328`：

1. 基线测试明确断言 `stage_01_01/02/04/05` 仍为 legacy，而本单冻结范围要求它们全部 migrated。
2. 基线结算测试断言旧的 5/9 敌人参与者 ID 集，而生产模板现为 2/3/25/40 敌人且要求每个 entry 唯一身份。
3. 基线键盘测试只按 J 就期待 stage01 胜利，而已冻结的 typed checkpoint 要求真实跨过 `x=520`。
4. 基线调优测试使用 `.single` 假设只有一个 runtime binding，全五关生产化后必须按 `stage_id` 选择。

将旧行改成注释、skip 旧测试、伪造 legacy 兼容或把生产范围缩回一关，都会触发 §9/§2 红线，不是合法修复。main `5e98ba1941fdb8a657c332fcaf9cf5a7f63fda7d` 新增的 §10 攒批与 §11 预授权也未改变 §8.2 对 `test_deletions` 的无豁免要求。因此本单必须依 §8.2 与 §9 标记真实 `[BLOCKED]`，等待用户修订外部判据或提供已迁移测试契约的新基线。

## 用户裁决后的测试契约迁移出口

main `f6c2b07dbf11922572b1b65d092cecefc9f4c42b` 于 2026-08-29 增加宪法 §8「唯一例外 · 测试契约迁移」和专用机器校验器，上述阻塞已解除。本分支已先合入该 main，并在 `docs/dispatch/phase2_wiring/test_contract_migrations/p2-m2-ch1-templates-20260829.yaml` 逐条登记模板命令实测的 15 个断言删除与 3 个用例删除。替代项均是同一约束的更强版本：五关遍历、migrated 路由、非空 encounter/runtime、生产 repository、显式 external projector、精确参与者集与缺 binding fail-closed。

专用校验器输出原文：

```text
[migration] expect 删 15 / 增 53;用例 删 3 / 增 9;登记 18 条
PASS: test_contract_migration
```

## 键盘接线测试的证据边界

`test/features/mainline/presentation/phase0a_mainline_wiring_test.dart` 为了让 25 敌接线探针在固定模拟窗口内走完键盘链，将测试注入玩家血量用 `copyWith` 提到 `150000`，超过 CLAUDE.md §5.4 的玩家血量配置硬红线 `20000`。该值只存在于测试 fixture，未进入生产配置；依用户裁决不因此打回本单，但证据标签必须收窄为：**只证明键盘输入链与 typed checkpoint 生产接线可到达**。它不证明 `stage_01_01` 在真实数值下可通关，不得作为关卡可玩性、生存性或难度验收证据；是否能打过与体感结论归 G2 真人试玩。
