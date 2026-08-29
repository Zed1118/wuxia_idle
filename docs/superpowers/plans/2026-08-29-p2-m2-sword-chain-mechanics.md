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
3. 进步斩先沿最终瞄向前冲，再冻结同拍命中集；位移 clamp 到既有 arena
   边界。攻击位移不得进入 checkpoint 事件来源，移动输入的真实跨线语义不改。
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
