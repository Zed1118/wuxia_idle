# P2-M2-R08：Production Encounter AttackToken 闸接线

## 目标与分支

- 分支：`codex/phase2-m2-r08-production-encounter-token-gate-20260824`
- 基线：`81d47f16880b2b9d7a860379cf308cca3f6110e2`
- 目标：让现有 production encounter assembler 显式接收调用方构造的
  `Phase0aEnemyIntentBatchGate`，并把同一实例透传到
  `Phase0aCombatSession`。

## 冻结合同

- 只给 `assembleEncounter` 和 `assembleEncounterFromMapping` 增加可选
  `Phase0aEnemyIntentBatchGate? enemyIntentBatchGate`，且只透传 exact
  caller instance。
- assembler 不创建 budgets / mapper / director / defaults，不推断角色或
  token kind，不接 production host。
- legacy `assemble(...)` 不改；null 路径保持原有语义。
- R05 已负责 session batch-gate 管线、identity 稳定子序列校验与
  fork 继承；本切片只验 production assembler/encounter flow 入口，不
  重复扩展 session 合同。
- RNG 证据只证明：grant-all gate 与 null 路径同 seed 消费序列
  相同，以及非法 gate 输出在 resolver/reducer 前失败；不宣称通用
  RNG rewind。
- 测试中 token budget 只是机制 fixture，不是生产调优值；
  `TUNE-ATTACK-TOKEN-01` promotion Gate 继续锁定。

## 验收清单（CLAUDE.md §8.2）

- [x] 生产接线证据：`Phase0aProductionFlowAssembler` 的两个 dynamic
  encounter 入口把显式 gate 交给真实 `Phase0aCombatSession`，未接
  host。
- [x] targeted tests：真实 `AttackTokenEnforcingBatchGate` 的多敌同拍预算
  筛选、observer/伤害一致性、null 等价、mapping exact-instance
  透传、非法输出 flow 原子失败全绿。
- [x] 红线：不改伤害/血量/内力/装备/招式数值，不触三系锁死、
  在线=离线、反主流清单或文案/数值硬编码。
- [x] 残留风险：production budgets / mapper / host promotion 仍在本切片外；
  本测试不证明失败后的通用 RNG rewind。
- [x] 非 UI 任务，无视口验收；无新中文 UI 字符串、高频日志、临时
  资产或 `.g.dart` 误提交。
- [x] scoped analyze 0 issue，format / `git diff --check` / owned-files 白名单
  均通过，main / origin main 不变。

## 任务切片

1. 读取 CLAUDE/GDD/已否清单、assembler/session/R05/encounter flow 与既有
   测试，准备 fresh worktree 依赖。
2. Pi + DeepSeek V4 Flash high 做设计/边界审查，triage 后冻结最小
   测试矩阵。
3. 先写专用 production encounter token-gate 红测，再做 assembler 最小
   透传实现。
4. 跑 targeted / scoped analyze / format / diff / 白名单与分支不变校验。
5. Pi + DeepSeek V4 Flash high 终审实际 diff，triage 后记录证据。
6. 提交实现与证据，追加精确 READY 空提交。

## Pi 设计审查

- 工具版本：Pi CLI `0.84.1`
- 提供商/模型：`deepseek/deepseek-v4-flash`
- thinking：`high`
- 结论：`PASS`，0 P0 / 3 P1 / 4 P2 建议。
- 已采纳：测试限定在 assembler 真实生产路径；用 observer 最终
  intent、命中事件和 HP 变化三方闭环验伤害；grant-all/null 对照
  证明不新增 RNG 消费；非法输出只验失败前界和 flow 原子恢复。
- 经 triage 不扩围：不重测 R05 session identity/fork 合同，不接
  host/YAML，不验证或宣称通用 RNG rewind，不硬编码预期伤害值。

## Pi 最终 diff 审查

- 工具版本：Pi CLI `0.84.1`
- 提供商/模型：`deepseek/deepseek-v4-flash`
- thinking：`high`
- 审查范围：实际 `git diff --cached`、3 个 owned files、R05 session/
  batch-gate/fork 与 encounter flow；Pi 实际核验基线/分支与
  `git diff --cached --check` exit 0。
- 结论：`PASS`，0 P0 / 0 P1 / 2 P2。两条 P2 分别是专用测试一条
  重复断言与最终验收复选框尚未勾选；前者已删，后者已在本次
  白名单/refs 终验后勾选。
- post-triage 用同版本/同模型/同 thinking 再审实际 staged diff：
  `PASS`，0 P0 / 0 P1 / 0 P2，明确可提交。

## 当前恢复点

- 状态：进行中，实现、回归、Pi 最终 diff 审查与终验完成，
  待提交实现/证据并追加 READY 空提交。
- 最后完成：专用 TDD 先以两个 assembler 入口缺参数红灯，最小
  透传后变绿；6 个相关测试文件分别 5/12/15/23/15/1，合计
  71/71 通过。
- 下一步：提交实现与证据，追加精确 READY 空提交。
- 已跑验证：`flutter pub get`；`dart run build_runner build`（126
  outputs）；`libisar.dylib` SHA-256 一致；targeted 71/71；两处
  scoped `dart analyze` 0 issue；`dart format --output=none
  --set-exit-if-changed` 0 pending；`git diff --check` exit 0；owned-files
  只有冻结的 3 文件；main 与 origin/main 均为
  `e292d3a069fbc0e129dd74fafc1ebb3746f53557`，原 main worktree clean。
- 阻塞项：无。
