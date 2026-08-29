# M2 剑形态三段普攻机制接线计划

## 结果合同

- 单一目标：在既有剑三段身份链上接通真实生产 reducer 的分段
  geometry、目标上限、进步斩位移和 per-segment 吸附参数；不重复实现
  已冻结的鼠标长按与鼠标朝向。
- 权威验收门：同一位置同一朝向下，侧方敌人超出直刺 `±0.35 rad` 但位于
  横扫 `±1.30 rad` 内，必须表现为直刺 miss、横扫 hit；进步斩位移不越
  arena、也不触发 `stage_01` 的 `x=520` checkpoint。最终以本单
  `gate.sh`、main 合并后全量和 GitHub CI 为准。
- 基线：`cdf8114ee5728eae22977e082cda0ef527896ee1`；分支
  `codex/p2-m2-sword-chain-mechanics-20260829`；worktree
  `/Users/a10506/Desktop/Projects/挂机武侠-p2-m2-sword-chain-mechanics-20260829`。
- 当前关键阻塞：已于 2026-08-29 解除。用户显式授权新增最小 typed
  `BasicAttackGeometryRegistry`，只登记现有三条 sword ref、复用
  `ForwardFanScope`、不改 Isar/saveVersion，缺 ref 必须 fail closed。
- 预期增量：M2 #4 从“只有段身份与不同 VFX”推进为“同一 reducer 中三段
  有真实力学差异”；局部 RED/提交不计完成。
- 成本上限：只保留这一项主 WIP；约 90 分钟无验收门进展即重评路线，
  本单不扩展到 timeline/idle reset、其他武器、POSTURE 或 M3/M4。

## 开局与宪法漂移

- `main == origin/main == cdf8114e...`，且 `03b2f0e8...`（五关四模板）
  是其祖先；前置单已合并，无需测试契约迁移解阻。
- 宪法当前 sha256 为 `084954be994c3d0ff67c4eec8a1e02cdb46f892a8a42fe978432e95117dbffd6`，
  §0 的 `main 274a3b2e...` 已漂移；原交接 hash 也已被后续 §8/§10/§11
  修订取代。
- 宪法 §3 #4 的“生产每次只发单段”已漂移：当前生产已经按
  `sword_thrust → sword_sweep → sword_advancing_slash` 发出 typed segment，
  但三段仍共用 `_selectStrikeTarget` 的相同 range/arc/单目标 resolver。
  本单修机制，不重做段身份或鼠标输入。
- `data/numbers.yaml` 原为 §7 禁区；本轮用户只覆盖授权在
  `player.attack_cooldown_seconds` 后原样新增给定的
  `basic_attack_chain` 块，其余任何行不改。

## Phase 0 生产基线（先量测、后改代码）

量测命令：

```text
flutter test --no-pub build/phase2_probe/phase0_sword_chain_baseline_probe_test.dart --reporter expanded
```

方法：从生产 `GameRepository` 加载 `stage_01_03` migrated catalog、runtime
binding 和 40 名敌人，通过 `createFreshPhase0aMainlineEncounter` 与
`steadyGuard` 共用正式 reducer；固定 seed `20260829`，只统计出手前活跃敌人
处于 `[8,16]` 的玩家 `Phase0aAttackStarted`/`Phase0aHitLanded`。临时 probe
位于已 gitignore 的 `build/`，不进入提交。相同命令连续两次输出一致：

```text
PHASE0_SWORD_BASELINE attacks=16 hits=15 average_hits_per_attack=0.937500 first_cycle_hits=2 first_cycle_segments=sword_thrust,sword_sweep,sword_advancing_slash max_active=12
00:00 +1: All tests passed!
```

三项基线：

1. 一次普攻平均命中 `0.9375` 名敌人（16 次出手、15 次命中）。
2. 今天有上限，等效上限为 `1`；生产符号
   `phase0a_combat_reducer.dart::_selectStrikeTarget` 对全部弧内候选排序后
   只 `return inArc.first`，尚无 per-segment `maxTargets` 配置。
3. 第一轮三段（固定冷却 `0.55s × 3 = 1.65s`）总命中数为 `2`，段序为
   `sword_thrust,sword_sweep,sword_advancing_slash`。

## 实现边界

1. 把用户给定 YAML 块解析为 typed per-segment tuning，并用
   `geometryRef` 注册表解析；实际判定复用既有 `ForwardFanScope`，禁止建立
   第二套几何核。registry 只登记三条现有 sword ref，绝不预建其余四种武器；
   registry 内不得出现数值字面量，缺 ref 直接抛错、禁止 fallback。
2. player+sword chain 走 per-segment range/half-arc/max-targets；无 chain、
   敌人和其他武器继续走现有 420/0.72 fallback 单目标语义。本轮三段
   `max_targets` 全部为 `1`，是否开放群伤留待用户试玩后单独拍板。
3. 进步斩先用该段同一个 `ForwardFanScope` 冻结命中集，再把
   `advance_distance` 作为位移上限：有目标时不越过冻结目标，无目标时完整
   前冲；resolver 直接消费这份冻结命中集，不在位移后另算一套。位移继续
   clamp 到既有 arena 边界，且不得进入 checkpoint 事件来源；移动输入的真实
   跨线语义不改。Phase0A 当前没有 actor 碰撞半径，接战余量沿既有点几何语义
   为零，不新增隐藏调优数值。
4. aim assist 从每段配置读；三段均为 `0.0` 时瞄向必须逐位保持现状。
5. 不修改 `phase0a_battle_screen.dart` 的 pointer down/move/up 或 held attack
   读取，不改 J、CD、POSTURE、自动普攻、文案和其他武器。

## RED 与验收

- 生产路径功能判据：侧方敌人在同一玩家位置与朝向下，直刺 miss、横扫 hit；
  不以多目标命中数作判据。
- fail-closed 判据：删掉任一现有 sword ref 映射，对应段必须抛错，禁止退回
  共用几何。
- 位移判据：进步斩在边界前停止，且从 `x<520` 前冲跨过该坐标不会产生
  checkpoint 事件；正常移动跨线仍产生，避免把 checkpoint 本身放松。
- 零吸附判据：配置为零时 event/facing/命中方向与输入完全一致。
- 提交后双向破坏证红：
  1. `remove_implementation` 移除生产 geometry registry 消费支点；
  2. `force_degenerate_value` 把横扫 `half_arc` 强制退化为与直刺相同；
     同一 targeted 组必须变红。
- 实装后用同一 probe/seed/场景复测三项；第一轮三段总命中若低于基线
  `2 × 70% = 1.4`（整数口径即 `≤1`），立即 `[BLOCKED]`，不自行调数值。

## 恢复点

- 当前：再次 `[BLOCKED]`，命中用户明示的“实装后三段总命中较 Phase 0
  基线下降 30% 以上”停止条件。不得自行调数值补回。
- 阻塞证据：全仓用 `geometryRef`、`GeometryRegistry`、`geometry.sword`、
  “几何注册”及 `ForwardFanScope` 消费点交叉反搜。结果只有：
  1. `basic_attack_chain.dart` 定义三条 opaque ref；
  2. `basic_attack_chain_test.dart` 检查 ref 身份；
  3. `realtime_combat_rules.dart` 直接临时构造 `ForwardFanScope(maxTargets: 1)`；
  4. 不存在任何按 ref 解析 scope/tuning 的 registry、catalog 或 resolver。
- 解阻决议：用户批准推荐方案；拒绝按 `segment.id` 写死 switch，并将
  `max_targets` 从旧候选 `3/10/5` 修正为 `1/1/1`，避免在未拍板群伤前把
  单体基线放大约六倍。
- 命名决议：统一使用生产约定 `geometry.sword.*`；单测旧
  `forward_fan.*` 全部迁到同一约定，不保留双轨 ref。

## 实装后同场景复测与第二次阻塞

同一 `stage_01_03` production repository、migrated encounter host、
`steadyGuard`、seed `20260829` 与活跃 `[8,16]` 过滤口径复测：

```text
PHASE0_SWORD_BASELINE attacks=27 hits=16 average_hits_per_attack=0.592593 first_cycle_hits=1 first_cycle_segments=sword_thrust,sword_sweep,sword_advancing_slash max_active=12
00:00 +1: All tests passed!
```

| 指标 | Phase 0 基线 | 当前实装 | 变化 |
|---|---:|---:|---:|
| 最大活跃敌人 | 12 | 12 | 0 |
| 一次普攻平均命中 | 0.937500 | 0.592593 | -36.79% |
| 第一轮三段总命中 | 2 | 1 | -50.00% |

第一轮总命中已落到整数停线 `≤1`，且全场平均同样下降超过 30%，故不再
运行后续调参、完整 gate、合并或 push。

停止前已取得的 targeted 证据：

- 初始 RED：registry/API 不存在时
  `basic_attack_geometry_registry_test.dart` 为
  `00:00 +0 -1: Some tests failed.`。
- registry/侧方 miss-hit/缺 ref/arena barrier/零吸附：
  `00:00 +5: All tests passed!`。
- production mapper/YAML typed 消费与原有五关 headless 邻接回归：
  `00:00 +25: All tests passed!`。
- stage_01_01 checkpoint：进步斩不完成 checkpoint clause，正常移动仍完成：
  `00:00 +1: All tests passed!`。
- 尚未进行 commit 后双向破坏证红、analyze、整仓 format、全量或 gate；本 tip
  只能是可恢复 WIP `[BLOCKED]`，不得视为候选完成。

## 目标感知截停授权与方法论修正

- 用户判定根因是实现形态而非数值：固定前冲 `120.0` 撞上实际目标前向距离
  `5.823–67.390`，使进步斩修前为 `0/8`；授权把该字段改成“位移上限”，
  目标由该段生产 geometry 选择并与 resolver 复用同一结果。锥内无目标时仍
  完整前冲。
- 明确否决把直刺 `half_arc` 从 `0.35` 放宽、把横扫从 `1.30` 放宽；两者维持
  段身份。后续不得用“覆盖当前 seed 最高需求”反推参数，命中率只用于发现
  某段是否坏死，数值身份由产品语义决定。
- `max_targets` 保持 `1/1/1`、`aim_assist` 保持 `0/0/0`、CD 不动；鼠标 held
  attack/pointer aim 与 J 键路径零改动。
- `data/numbers.yaml` 只在进步斩 `advance_distance` 上方增加授权注释
  “位移上限,实际受目标截停”，数值仍为 `120.0`，其余行不改。

## 同 seed 修前/修后证据

固定 `stage_01_03`、seed `20260829`、生产 repository/runtime、
`steadyGuard` 与活跃 `[8,16]` 过滤。修前与修后均用 gitignore 的同一
`build/phase2_probe/phase0_sword_chain_miss_diagnostic_test.dart`；probe 不进
diff。先保留自由运行轨迹实测，再以同一攻击时刻状态的成对重放作为降幅判据，
避免位移改变后续站位后拿不同分母直接相减。

自由运行实测（轨迹会随位移语义分叉，完整保留但不作同布局降幅判决）：

| 段 | 修前命中/出手 | 修后命中/出手 | 修前命中率 | 修后命中率 |
|---|---:|---:|---:|---:|
| 直刺 | 7/9 | 5/8 | 0.777778 | 0.625000 |
| 横扫 | 9/10 | 6/8 | 0.900000 | 0.750000 |
| 进步斩 | 0/8 | 4/7 | 0.000000 | 0.571429 |
| 合计 | 16/27 | 15/23 | 0.592593 | 0.652174 |

同布局成对重放（权威降幅判据）：

| 段 | 修前命中/出手 | 修后命中/出手 | 修前命中率 | 修后命中率 |
|---|---:|---:|---:|---:|
| 直刺 | 3/4 | 3/4 | 0.750000 | 0.750000 |
| 横扫 | 5/6 | 5/6 | 0.833333 | 0.833333 |
| 进步斩 | 0/6 | 6/6 | 0.000000 | 1.000000 |
| 合计 | 8/16 | 14/16 | 0.500000 | 0.875000 |

同布局生产 fallback 基线为 `15/16 = 0.937500`；修后
`14/16 = 0.875000`，相对降幅 `6.67%`，小于停止线 `30%`。修后进步斩已与
其余两段同量级；自由运行的三段也从单段 `0/8` 坏死恢复为
`5/8、6/8、4/7` 同量级。修后完整输出：
`build/phase2_probe/phase0_sword_chain_miss_diagnostic_after_output.txt`。

## 当前恢复点（目标感知截停）

- 状态：生产实现、同 seed probe、第一轮提交后双向破坏证红和邻接 targeted
  均通过；当前在最终 `[READY]` tip 前收口计划与静态检查，尚未跑最终 full/gate。
- 生产路径：`Phase0aPlayerInputAdapter → Phase0aAttackIntent →
  phase0a_combat_reducer.dart`；reducer 在位移前只调用一次 segment scope，
  同一 `selectedGeometryTargets` 同时决定截停目标和 resolver 目标。
- RED：固定 `120` 旧行为下，目标感知测试实测
  `Expected ArenaVector(60,0), Actual ArenaVector(120,0)`，reporter
  `00:00 +6 -1: Some tests failed.`；实现后同文件 `+7` 全绿。
- 提交 `15c23010` 后第一轮双向破坏证红：
  1. `remove_implementation`：移除 reducer 的 `stopTarget` 传递，退回固定
     `120`，同一测试组实测 `00:00 +6 -1: Some tests failed.`；
  2. `force_degenerate_value`：保留接线但强制 `travelDistance = distance`，
     同样实测 `00:00 +6 -1: Some tests failed.`。
  两向均由精确反向补丁还原，分别核 `git diff --quiet` rc=0。最终
  `[READY]` tip 形成后须再跑一次同体例双向证红，receipt 只记最终 tip 数据。
- 邻接 targeted：registry `+7`、chain `+6`、production mapper/五关 headless
  `+25`、stage_01_01 checkpoint `+1`，四次均逐文件出现
  `All tests passed!`。
- `flutter analyze --no-pub lib test` 初跑发现本分支既有 YAML parser 两处
  `prefer_const_constructors`；只补 `const FormatException` 后复跑
  `No issues found! (ran in 3.2s)`。整仓 format 先定位并格式化 gitignore probe，
  再复跑为 `Formatted 1642 files (0 changed) in 2.76 seconds.`。
- 阻塞项：无。当前仍是 WIP，未取得 gate/CI 结论前不得报 READY。

## 完整套件契约迁移

- 首轮最终 full 为 `04:57 +5686 -9: Some tests failed.`；9 个失败全部来自
  3 个表现层文件共用的旧终局制造方式：原地只发
  `Phase0aPlayerCommand(attack: true)`，并把“2000 拍必胜”误当成重试、焦点
  或音效接线的前提。失败均是期望 `victory`、实际 `defeat`，没有出现第 10
  种错误。
- 替代驱动复用生产 `Phase0aPlayerCommand`、真实敌人列表与真实 reducer：每拍
  朝当前首个存活敌人移动，同时按真实可用性发普攻和清场技。它继续要求确定性
  fixture 真实到达胜利终局，但不再把静止单一普攻的数值强弱冒充表现层契约；
  原有重试、焦点、逐事件音效和胜利 jingle 断言全部保留。
- 三个原失败文件合跑为 `00:02 +20: All tests passed!`。本迁移只用于构造表现层
  所需终局，不证明任何 `stage_01` 关卡可通关；关卡强度仍归 G2 真人试玩。
- 因本分支还统一了旧 `forward_fan.*` 测试 ref，并替换上述 4 个旧驱动调用，
  `gate.sh` 的 `test_deletions` 将按设计留红；随本单登记
  `p2-m2-sword-chain-mechanics-20260829.yaml` 并运行
  `tools/test_contract_migration_gate.sh`。
- 迁移后完整套件为 `05:18 +5695: All tests passed!`，`[E]` 块为 `0`；最终
  静态与格式检查分别为 `No issues found! (ran in 2.9s)`、
  `Formatted 1643 files (0 changed) in 2.83 seconds.`。
- 测试契约迁移校验器原文：

```text
[migration] expect 删 2 / 增 27;用例 删 0 / 增 8;登记 2 条
PASS: test_contract_migration
```
