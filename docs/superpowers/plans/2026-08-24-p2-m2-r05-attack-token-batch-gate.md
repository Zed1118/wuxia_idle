# P2-M2-R05：AttackToken 批次执行闸

## 目标与分支

- 分支：`codex/phase2-m2-r05-attack-token-batch-gate-20260824`
- 基线：Batch11 READY `57f04b397d1412128535ba8f74a7e61ecdfb4577`
- 目标：在现有逐 intent 出生宽限 gate 之后、observer/reducer 之前增加可选批次 gate，并用显式注入的 `AttackTokenDirector` / budgets / mapper 实际过滤未获准的攻击 intent。

## 冻结合同

- 管线顺序固定为 enemy AI → 逐 intent gate → 批次 gate → observer → reducer。
- null 批次 gate 不增加拷贝、mapper 或 director 调用，保持旧路径。
- session 只接受 batch gate 返回的输入对象 identity 稳定、无重复子序列；使用 `identical`，不依赖 `==`，禁止注入、替换、重复、重排。输入只物化一次且以不可修改副本交付 gate，验证后再包装不可修改输出。
- `AttackTokenEnforcingBatchGate` 的 mapper 返回 null 表示非 token intent，原对象原样放行；非 null request 的 actorId 必须等于 intent.actorId。
- director denied 的 token intent 过滤，granted 与非 token intent 保持输入顺序。同 actor 的多个 token request 继承 director 的 duplicate actorId fail-closed；现有 AI adapter 每 actor 每拍只产生一个 intent，本切片不对原始输入新增 actor 去重或改写语义。
- mapper/director/gate/子序列验证任一异常均在 observer/reducer 前传播；session state 与 `lastEnemyIntentObservation` 不推进。
- `forkWithState` 与 `forkWithStateAndEnemyIntentGate` 保留同一 batch gate identity。budget 属于整个 session/encounter 的显式依赖，本切片不增加按波动态替换接口。
- 不接 production host / YAML / UI / save / reward / injury，不提供调优默认值，不从 intent 推断 token 类型或角色。

## 验收清单（CLAUDE.md §8.2）

- [x] 生产接线证据：真实 `Phase0aCombatSession.advance` 消费 batch gate，不停在 fixture/demo；production host 仍按冻结范围显式未装配。
- [x] targeted test：专用 gate 测试 + session encounter seams + observe-only + director 回归共 61/61 全绿。
- [x] 红线：不改任何伤害/血量/内力/装备/招式数值，不触三系锁死、在线=离线、反主流清单或文案/数值硬编码。
- [x] 残留风险：candidate budgets 与 production host 仍受 promotion Gate 锁定；本批只交付执行机制，不宣称完成玩法调优。
- [x] 非 UI 任务，不需桌面视口验收；无新中文 UI 字符串、高频日志、临时资产或 `.g.dart` 误提交。
- [x] scoped analyze 0 issue，`git diff --check` 干净，工作树 clean，tip 为 `[READY][PI][P2-M2-R05]`。

## 任务切片

1. 先写 batch gate 合同、AttackToken enforcing 与 session 原子性红测。
2. 实现 batch gate 抽象、identity 子序列验证与 AttackToken 执行 gate。
3. 最小修改 session/fork，跑 targeted/analyze/diff 验证。
4. Pi + DeepSeek V4 Flash 终审实际 diff，triage 后记录证据。
5. 提交实现/证据并追加 READY 空提交。

## Pi 设计审查

- 工具版本：Pi CLI `0.84.1`
- 提供商/模型：`deepseek/deepseek-v4-flash`（`--thinking high`）
- 结论：`NEEDS_CHANGES`，0 P0 / 4 P1 / 6 P2。
- 已采纳：identity 验证必须用 `identical`；gate 输入只物化一次并防御性包装；两个现有 fork 入口与换波路径都要保留 identity；覆盖异常原子性和运行时非 const identity 测试。
- 经 triage 不扩范围：对两个 null mapper 的同 actor 原始 intent 去重属于 AI adapter/reducer 的旧输入合同，batch gate 只能返回原输入子序列，不引入新重复；动态替换 budgets 与新的对称 fork API 不属于本切片，整个 session 使用同一显式 gate。

## Pi 最终 diff 审查

- 工具版本：Pi CLI `0.84.1`
- 提供商/模型：`deepseek/deepseek-v4-flash`（`--thinking high`）
- 审查范围：实际 git diff、两个新建生产文件、session 接线、专用测试、session seams 与 director。
- 复跑证据：61/61；scoped 与 battle feature 宽范围 analyze 均 0 issue；`git diff --check` exit 0。
- 结论：`PASS`，0 P0 / 0 P1 / 0 P2；只记录了每拍小规模下可忽略的分配与 O(n²) identity 去重信息项，不影响正确性。

## 当前恢复点

- 状态：完成，已以分支当前 `[READY][PI][P2-M2-R05]` tip 冻结。
- 最后完成：实现提交 `ddce919f`、证据提交 `2c7409e5`；Pi/DeepSeek 设计审查经 triage 后落实，最终 diff 终审 PASS，P0/P1/P2=0。
- 下一步：由 Batch12 主控审查、集成并跑批末验证。
- 已跑验证：`flutter test --no-pub` 四文件联合 61/61；变更 5 个 Dart 文件 scoped `dart analyze` 0 issue；`dart format` 0 pending；`git diff --check` 干净。fresh worktree 首次 `--no-pub` 命中 Flutter 3.41.5 native-assets `Bad state: No element`，执行 `flutter pub get` + `dart run build_runner build`（126 outputs）并复制 shasum 一致的 `libisar.dylib` 后消解，属环境而非代码缺陷。
- 阻塞项：无；production tuning/host promotion 明确不在本切片。
